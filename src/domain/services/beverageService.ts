import "reflect-metadata";
import { Beverage } from '../models/Beverage';
import { Recipe } from '../models/Recipe';
import { RecipeRepository } from '../../infrastructure/repositories/recipeRepository'
import { IngredientsRepository } from '../../infrastructure/repositories/ingredientsRepository'
import { DENOMINATIONS } from '../constants';
import { autoInjectable } from "tsyringe";
import { Coin } from "../models/Coin";
import { BadRequest } from "../models/BadRequest";
import { Ingredient } from "domain/models/Ingredient";
import { TransactionBroadcaster } from "../../infrastructure/connectors/transactionBroadcaster";

@autoInjectable()
export class BeverageService {

    constructor(
        private recipeRepository: RecipeRepository, 
        private ingredientsRepository: IngredientsRepository) {      
    }

    public GetBeverages(): { [beverageName: string]: { recipe: Recipe, price: number } } {
        return this.recipeRepository.GetAllRecipes();
    }

    public GetIngredients(): { [ingredientName: string]: Ingredient } {
        return this.ingredientsRepository.getAllIngredients();
    }

    public async PrepareBeverage(beverageName: string, sugarLevel: number, coins: Coin[]): Promise<{ change: Coin[], txId: string }> {
        this.validate(beverageName, sugarLevel, coins);
        const recipe = this.recipeRepository.GetRecipe(beverageName);
        if (!recipe) {
            throw new BadRequest('Beverage not found');
        }

        const amount = this.calculateSum(coins);
        if (recipe.price > amount) {
            throw new BadRequest('Insufficient funds');
        }

        const beverage = new Beverage(beverageName, recipe.recipe.getIngredients(), sugarLevel);

        if (beverage.prepare(this.ingredientsRepository.getAllIngredients())) {
            const change = amount - recipe.price;

            // const txId = await new TransactionBroadcaster().SendAsync(JSON.stringify({ "beverage": beverageName, "paid": amount, "change": change }));
            const txId = '1234567890abcdef'; // Placeholder for transaction ID
            return  { change: this.calculateChange(change), txId };
        } else {
           throw new BadRequest(`Cannot prepare ${beverageName}. Not enough ingredients.`);
        }
    }

    private validate(beverageName: string, sugarLevel: number, coins: Coin[]) {
        if (!beverageName || !coins) {
            throw new BadRequest("beverageName and coins are required");
        }

        if (!Number.isInteger(sugarLevel) || sugarLevel < 1 || sugarLevel > 5){
            throw new BadRequest("sugarLevel must be a whole number between 1 and 5");
        }
    }

    private calculateSum(coins: Coin[]): number {
        const sum = coins.reduce((sum, coin) => sum + coin.getDenomination(), 0);
        return Math.round(sum * 100) / 100; // Round to 2 decimal places
    }

    private calculateChange(amount: number): Coin[] {
        const change: Coin[] = [];
        let remainingAmount = amount;

        for (const denomination of DENOMINATIONS) {
            while (remainingAmount >= denomination) {
                change.push(new Coin(denomination));
                remainingAmount -= denomination;
            }
        }

        return change;
    }
}