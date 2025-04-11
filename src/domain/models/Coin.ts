import { DENOMINATIONS } from '../constants';
import { BadRequest } from './BadRequest';

export class Coin {
    private denomination: number;

    constructor(denomination: number) {
        
        if (!DENOMINATIONS.includes(denomination)) {
            throw new BadRequest(`Invalid coin denomination. Allowed denominations are: ${DENOMINATIONS.join(', ')}`);
        }
        this.denomination = denomination;
    }

    getDenomination(): number {
        return this.denomination;
    }
}