import { singleton } from "tsyringe";
import { Recipe } from "../../domain/models/Recipe";

@singleton()
export class RecipeRepository {
    private recipes: { [beverageName: string]: { recipe: Recipe, price: number } };

    constructor() {
        this.recipes = {};
        this.initializeRecipes();
    }

    private initializeRecipes(): void {
        this.AddRecipe('coffee', new Recipe({ water: 1, coffee: 1 }), 2.50);
        this.AddRecipe('tea', new Recipe({ water: 1, tea: 1 }), 2.00);
        this.AddRecipe('hotChocolate', new Recipe({ milk: 2, chocolate: 1 }), 2.70);
        this.AddRecipe('latte', new Recipe({ milk: 2, coffee: 1 }), 3.50);
        this.AddRecipe('cappuccino', new Recipe({ milk: 1, coffee: 1 }), 3.20);
    }

    public GetRecipe(beverageName: string): { recipe: Recipe, price: number } | undefined {
        return this.recipes[beverageName];
    }    

    public GetAllRecipes(): { [beverageName: string]: { recipe: Recipe, price: number } } {
        return this.recipes;
    }

    public AddRecipe(beverageName: string, recipe: Recipe, price: number) : void {
        this.recipes[beverageName] = { recipe, price };
    }
}