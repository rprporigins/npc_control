import { faBasketShopping, faCarBurst, faCaretRight, faCartShopping, faIndianRupee, faIndianRupeeSign, faMoneyBill, faUserShield, faX, faXmark } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import React, { useState } from "react";
import ItemCard from "../components/ItemCard";
import { IItem, ItemType } from "../types/types.d";
import { fetchNui } from "../utils/fetchNui";

interface ListItemProps {
    items: IItem[];
}

const ListItem = ({items} : ListItemProps) => {
	return (
		<div className="vehicle-list-items w-full h-full">
			{items.map((item) => (
				<div className="vehicle-list-item flex flex-row">
					{item.name}
				</div>
			))}
		</div>
	);
}

interface ItemTypeSelectProps {
    value: ItemType | ''; // Allow empty string for initial/empty selection
    onChange: (value: ItemType) => void;
}

const ItemTypeSelect = ({ value, onChange }: ItemTypeSelectProps) => {
    // Array of possible ItemType values
    const itemTypes: ItemType[] = ["car", "truck", "bike", "weapon"];

    return (
        <select
            value={value}
            onChange={(e) => onChange(e.target.value as ItemType)}
            className="item-type-select"
        >
            <option value="" disabled>
                Selecione uma categoria.
            </option>
            {itemTypes.map((type) => (
                <option key={type} value={type}>
                    {type.charAt(0).toUpperCase() + type.slice(1)} {/* Capitalize for display */}
                </option>
            ))}
        </select>
    );
};

interface AdminMenuProps {
	items: IItem[];
}

const AdminMenu: React.FC<AdminMenuProps> = ({items}) => {
	const [selectedType, setSelectedType] = useState<ItemType | ''>(''); // State for selected type
	
	const handleBtn = async () =>  {
		const inputHash = (document.querySelector('input[name="input-hash"]') as HTMLInputElement)?.value;
		const inputName = (document.querySelector('input[name="input-name"]') as HTMLInputElement)?.value;
		const inputPriceR = (document.querySelector('input[name="input-priceR"]') as HTMLInputElement)?.value;
		const inputPriceC = (document.querySelector('input[name="input-priceC"]') as HTMLInputElement)?.value;
		const inputImgUrl = (document.querySelector('input[name="input-img-url"]') as HTMLInputElement)?.value;
		const inputInfo = (document.querySelector('input[name="input-info"]') as HTMLInputElement)?.value;
		const inputPermaCheck = (document.querySelector('input[name="input-permaCheck"]') as HTMLInputElement)?.checked;

		const newItem: IItem = {
			id: inputHash,
			name: inputName,
			priceR: parseFloat(inputPriceR),
			priceC: parseFloat(inputPriceC),
			imgUrl: inputImgUrl,
			info: inputInfo,
			type: selectedType as ItemType,
			perma: inputPermaCheck,
		}

		await fetchNui('rp_store:client:createItem', newItem);
		await fetchNui('rp_store:client:getAllItems')
	};

	const itemss: IItem[] = [
		{
			id: "1",
			name: "Elegy Retro RH5",
			priceR: 5000,
			priceC: 7500,
			imgUrl: "/images/elegy_retro_rh5.png",
			info: "Um carro esportivo clássico, perfeito para corridas.",
			type: "car",
			perma: true,
		},
		{
			id: "2",
			name: "Bati 801",
			priceR: 3000,
			priceC: 4500,
			imgUrl: "/images/bati_801.png",
			info: "Uma moto rápida e ágil, ideal para a cidade.",
			type: "bike",
			perma: false
		},
		{
			id: "2",
			name: "Bati 801",
			priceR: 3000,
			priceC: 4500,
			imgUrl: "/images/bati_801.png",
			info: "Uma moto rápida e ágil, ideal para a cidade.",
			type: "bike",
			perma: true,
		},
	];
	return (

		<div className="admin-menu-wrapper">
			<div className="vehicle-list">
				<ListItem items={items} />
			</div>
			<div className="vehicle-config">
				<div className="vehicle-config-row">
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">*Hash (spawn):</span>
						<input type="text" name="input-hash" />
					</div>
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">*Nome:</span>
						<input type="text" name="input-name" />
					</div>
				</div>
				<div className="vehicle-config-row">
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">*Preço Ribeirinhos:</span>
						<input type="text" name="input-priceR" />
					</div>
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">Preço Dinheiro:</span>
						<input type="text" name="input-priceC" />
					</div>
				</div>
				<div className="vehicle-config-row">
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">Url da Imagem:</span>
						<input type="text" name="input-img-url" />
					</div>
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">Info:</span>
						<input type="text" name="input-info" />
					</div>
				</div>

				<div className="vehicle-config-row">
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">Categoria:</span>
						<ItemTypeSelect
							value={selectedType}
							onChange={(value) => setSelectedType(value)}
						/>
					</div>
					<div className="vehicle-config-input-wrapper">
						<span className="vehicle-config-title">Permanente:</span>
						<input type="checkbox" name="input-permaCheck"/>
					</div>
				</div>

				<div className="vehicle-config-row">
					<div className="vehicle-config-input-wrapper">
						<button className="btn-submit" onClick={handleBtn}> Cadastrar</button>
					</div>
				</div>
			</div>
			
			
		</div>

	);
};

export default AdminMenu;