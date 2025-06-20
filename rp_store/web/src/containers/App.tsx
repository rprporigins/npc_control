import React, { useCallback, useEffect, useState } from "react";
import { debugData } from "../utils/debugData";
import { useNavigationState } from "../atoms/navigationAtom";
import Catalog from "./Catalog";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faCaretRight, faIndianRupeeSign, faUserShield, faXmark } from "@fortawesome/free-solid-svg-icons";
import AdminMenu from "./AdminMenu";
import { IItem } from "../types/types.d";
import { fetchNui } from "../utils/fetchNui";
import { useNuiEvent } from "../hooks/useNuiEvent";

// This will set the NUI to visible if we are
// developing in browser
debugData([
    {
        action: "setVisible",
        data: true,
    },
]);

const App: React.FC = () => {
    const [navigationState, setNavigationState] = useNavigationState();
    const [items, setItems] = useState<IItem[]>([]);

    const fetchItems = useCallback(async () => {
        try {
            await fetchNui('rp_store:client:getAllItems');
        } catch (error) {
            console.error('Error fetching items:', error);
        }
    }, []);

    useNuiEvent('rp_store:setItems', (data: { success: boolean; items?: IItem[]; error?: string }) => {
        console.log("Received items:", data.items?.length);
        if (data && data.success && data.items) {
            setItems(data.items);
        }
    });

    const renderPage = React.useCallback(() => {
        switch (navigationState.path) {
            case 'catalog':
                return <Catalog items={items} />;
            case 'admin-menu':
                return <AdminMenu items={items} />;
            default:
                return <Catalog items={items} />;
        }
    }, [navigationState, items]);

    const handleBtnAdminClick = () => {
        setNavigationState({ path: 'admin-menu' });
    };

	const handleCategoryClick = () => {
        setNavigationState({ path: 'catalog' });
    };

    useEffect(() => {
        fetchItems();
    }, [fetchItems]);

    return (
        <div className="flex flex-col min-h-screen">
            <div id="main-wrapper">
                <div id="top-menu">
                    <div className="mr-20">
                        <FontAwesomeIcon
                            className="btn-admin"
                            onClick={handleBtnAdminClick}
                            fontSize={'1.2vw'}
                            icon={faUserShield}
                        />
                        <FontAwesomeIcon fontSize={'0.6vw'} icon={faIndianRupeeSign} /> 26300 +
                    </div>
                    <div className="mr-8 font-bold">
                        <FontAwesomeIcon fontSize={'0.7vw'} icon={faXmark} />
                    </div>
                </div>

                <div id="left-section">
                    <div className="catalog-types">
                        <h5>Categorias</h5>
                        <div className="active" onClick={handleCategoryClick}>
                            <FontAwesomeIcon icon={faCaretRight} />&nbsp;&nbsp;
                            <span>Carros</span>
                        </div>
                        <div>
                            <FontAwesomeIcon icon={faCaretRight} />&nbsp;&nbsp;
                            <span>Motos</span>
                        </div>
                        <div>
                            <FontAwesomeIcon icon={faCaretRight} />&nbsp;&nbsp;
                            <span>Caminhões</span>
                        </div>
                        <div>
                            <FontAwesomeIcon icon={faCaretRight} />&nbsp;&nbsp;
                            <span>Armas</span>
                        </div>
                    </div>
                </div>

                <div id="right-section">
                    {renderPage()}
                </div>
            </div>
        </div>
    );
};

export default App;