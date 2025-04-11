export class Beverage {
    name: string;
    change: number[];
    txId: string;

    constructor(name: string, change: number[], txId: string | null) {
        this.name = name;
        this.change = change;
        this.txId = txId;
    }
}