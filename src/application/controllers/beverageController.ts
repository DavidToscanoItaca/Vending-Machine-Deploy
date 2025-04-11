import "reflect-metadata";
import { Request, Response } from 'express';
import { autoInjectable } from "tsyringe";
import { BeverageService } from '../../domain/services/beverageService';
import { Coin } from "../../domain/models/Coin";
import { BadRequest } from "../../domain/models/BadRequest";
import { BeverageInfo } from "../dtos/BeverageInfo";
import { Beverage } from "../dtos/Beverage";
import { Ingredient } from "../dtos/Ingredient";

@autoInjectable()
export class BeverageController {
    constructor(private beverageService: BeverageService) { }

    public GetBeverages(req: Request, res: Response) {
        const beverages = this.beverageService.GetBeverages();
        
        const beverageList: BeverageInfo[] = Object.keys(beverages).map(beverageName => {
            return new BeverageInfo(beverageName, beverages[beverageName].price);
        });

        res.status(200).json(beverageList).end();
    };

    public GetIngredients(req: Request, res: Response) {
        const ingredients = this.beverageService.GetIngredients();
        
        const ingredientList: Ingredient[] = Object.keys(ingredients).map(name => {
            return new Ingredient(name, ingredients[name].quantity);
        });

        res.status(200).json(ingredientList).end();
    };

    public async PrepareBeverage(req: Request, res: Response) {
        const { beverageName, sugarLevel, coins }: { beverageName: string, sugarLevel: number | null, coins: number[] } = req.body;
        
        try {
            const { change, txId } = await this.beverageService.PrepareBeverage(beverageName, sugarLevel, coins.map(x => new Coin(x)));
            return res.status(200).json(new Beverage(beverageName, change.map(x => x.getDenomination()), txId)).end()
        } catch (error) {
            if (error instanceof BadRequest) {
                res.statusMessage = error.message;
                return res.sendStatus(400).end();
            }
            else {
                console.log(error);
                return res.sendStatus(500).end();
            }
        }
    };

}