const { PrivateKey, P2PKH, Transaction, Script, ARC } = require('@bsv/sdk');
const fs = require('fs');

export class TransactionBroadcaster {
    
    privKey: any;
    broadcasterUrl: string;
    apiKey: string;
    sourceTransaction: any;
    fundTransactionFile: string;

    constructor() {
        this.privKey = PrivateKey.fromWif(process.env.PKEY);
        this.apiKey = process.env.BROADCASTER_APIKEY;
        this.fundTransactionFile = process.env.FUND_TRANSACTION;   
        this.broadcasterUrl = process.env.BROADCASTER_URL;
    }

    public async SendAsync(jsonStr: string) : Promise<string> {              
        // create transaction
        const tx = await this.buildTx(jsonStr);

        // Broadcast the transaction
        const t = await tx.broadcast(new ARC(this.broadcasterUrl, this.apiKey));

        // Save the raw transaction to a file
        await fs.promises.writeFile(this.fundTransactionFile, tx.toHex());
        return t.txid;
    }

    private async buildTx(jsonStr: string): Promise<any> {
        const transaction = await this.readLastTransaction();

        if (!transaction) {
            throw Error("Transaction cannot be published. Funding transaction is missing.");
        }

        const sourceTransaction = Transaction.fromHex(transaction);
        const tx = new Transaction();

        tx.addInput({
            sourceTransaction: sourceTransaction,
            sourceOutputIndex: 0,
            unlockingScriptTemplate: new P2PKH().unlock(this.privKey),
        });
        tx.addOutput({
            lockingScript: new P2PKH().lock(this.privKey.toPublicKey().toHash()),
            change: true
        });
        
        // Add JSON data as an OP_RETURN output
        tx.addOutput({
            lockingScript: Script.fromASM(`OP_RETURN ${Buffer.from(jsonStr).toString('hex')}`),
            satoshis: 0
        });

        await tx.fee();       
        await tx.sign();        
        return tx;
    }

    async readLastTransaction() : Promise<string> {
        let transaction;
        try {
            await fs.promises.access(this.fundTransactionFile, fs.constants.F_OK);
            transaction = await fs.promises.readFile(this.fundTransactionFile, 'utf8');
        } catch (error) {
            console.log(error);
        }   
        return transaction;
    }
}