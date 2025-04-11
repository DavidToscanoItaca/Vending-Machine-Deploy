import "reflect-metadata";
import { Router } from "express";
import express from "express";
import { container } from "tsyringe";
import { BeverageController } from "../../application/controllers/beverageController";

const router = Router();

export default(): express.Router => {
    router.get('/beverages', (req, res) => container.resolve(BeverageController).GetBeverages(req, res));
    router.post('/beverages', (req, res) => container.resolve(BeverageController).PrepareBeverage(req, res));
    router.get('/ingredients', (req, res) => container.resolve(BeverageController).GetIngredients(req, res));
    return router;
}
