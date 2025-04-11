export class Ingredient {
    name: string;
    quantity: number;

    constructor(name: string, quantity: number) {
        this.name = name;
        this.quantity = quantity;
    }

    use(amount: number): boolean {
        if (this.quantity >= amount) {
            this.quantity -= amount;
            return true;
        }
        return false;
    }

    refill(amount: number): void {
        this.quantity += amount;
    }
}