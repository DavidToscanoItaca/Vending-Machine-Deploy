import { SUGAR } from "../constants";
import { Ingredient } from "./Ingredient";

export class Beverage {
    name: string;
    recipe: { [key: string]: number };
    sugarLevel: number;

    constructor(name: string, recipe: { [key: string]: number }, sugarLevel: number) {
        this.name = name;
        this.recipe = recipe;
        this.sugarLevel = sugarLevel;
    }

    private canPrepare(ingredients: { [key: string]: Ingredient }): boolean {
        for (const [ingredientName, quantity] of Object.entries(this.recipe)) {
            if (!ingredients[ingredientName] || ingredients[ingredientName].quantity < quantity) {
                return false;
            }
            if (!ingredients[SUGAR] || ingredients['sugar'].quantity < this.sugarLevel) {
                return false;
            }
        }
        return true;
    }

    prepare(ingredients: { [key: string]: Ingredient }): boolean {
        if (this.canPrepare(ingredients)) {
            for (const [ingredientName, quantity] of Object.entries(this.recipe)) {
                ingredients[ingredientName].use(quantity);
            }
            ingredients['sugar'].use(this.sugarLevel);
            return true;
        }
        return false;
    }
}
