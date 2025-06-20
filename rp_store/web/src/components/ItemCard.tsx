import { faBasketShopping, faCarBurst, faIndianRupeeSign, faShop } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import React from "react";
import { IItem } from "../types/types.d";

interface ItemCardProps {
	item: IItem;
}

const ItemCard: React.FC<ItemCardProps> = ({ item }) => {
	return (
		<div className="item-card">
			<div className="item-card-image"></div>
			<div className="item-card-name">{item.name}</div>
			<div className="item-card-info">
				<em>{item.info}</em>
			</div>
			<div className="item-card-price">
				<FontAwesomeIcon fontSize={"0.8vw"} icon={faIndianRupeeSign} />&nbsp;
				{item.priceR.toLocaleString()} 
				<em>&nbsp;/ R$ {item.priceC}</em>
			</div>
			<div className="item-card-price-brl">
				<em>&nbsp;por mes</em>
			</div>
			<div className="item-card-buttons">
				<div className="item-card-button">
					<FontAwesomeIcon fontSize={'0.7vw'} color="white" icon={faShop} />&nbsp;&nbsp;
					<span>COMPRAR</span>
				</div>
				<div className="item-card-button">
					<FontAwesomeIcon fontSize={'0.8vw'} color="white" icon={faCarBurst} />
				</div>
			</div>

		</div>
	);
};

export default ItemCard;