import { faBasketShopping, faCarBurst, faCaretRight, faCartShopping, faIndianRupee, faIndianRupeeSign, faMoneyBill, faUserShield, faX, faXmark } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import React from "react";
import ItemCard from "../components/ItemCard";
import { IItem } from "../types/types.d";

interface CatalogProps {
    items: IItem[];
}

const Catalog: React.FC<CatalogProps> = ({ items }) => {
    // Chunk items into rows of 6
    const chunkedItems: IItem[][] = [];
    for (let i = 0; i < items.length; i += 6) {
        chunkedItems.push(items.slice(i, i + 6));
    }

    return (
        <div className="flex flex-col w-full h-full">
            {chunkedItems.map((rowItems, rowIndex) => (
                <div key={rowIndex} className="item-grid-row">
                    {rowItems.map((item) => (
                        <ItemCard key={item.id} item={item} />
                    ))}
                </div>
            ))}
        </div>
    );
};

export default Catalog;