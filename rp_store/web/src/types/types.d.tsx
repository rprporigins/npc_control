export type ItemType = "car" | "truck" | "bike" | "weapon";

export interface IItem {
	id: string;
	name: string;
	priceR: number;
	priceC: number;
	imgUrl: string;
	info: string;
	type: ItemType;
	perma: boolean;
}