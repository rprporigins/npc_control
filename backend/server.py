from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List, Optional
import uuid
from datetime import datetime
from enum import Enum
import re

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI(title="Gang NPC Manager API", description="Sistema de gerenciamento de NPCs para FiveM")

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Gang Types
class GangType(str, Enum):
    BALLAS = "ballas"
    GROVE_STREET = "grove_street"
    VAGOS = "vagos"
    LOST_MC = "lost_mc"
    TRIADS = "triads"
    ARMENIAN_MAFIA = "armenian_mafia"

# Gang configurations
GANG_CONFIG = {
    GangType.BALLAS: {
        "name": "Ballas",
        "color": "#800080",
        "models": ["g_m_y_ballaseast_01", "g_m_y_ballasorig_01", "g_m_y_ballasouth_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_MICROSMG", "WEAPON_MACHETE", "WEAPON_PUMPSHOTGUN"]
    },
    GangType.GROVE_STREET: {
        "name": "Grove Street Families",
        "color": "#00FF00",
        "models": ["g_m_y_famca_01", "g_m_y_famdnf_01", "g_m_y_famfor_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_KNIFE", "WEAPON_ASSAULTRIFLE"]
    },
    GangType.VAGOS: {
        "name": "Los Santos Vagos",
        "color": "#FFFF00",
        "models": ["g_m_y_mexgang_01", "g_m_y_mexgoon_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_MICROSMG", "WEAPON_SAWNOFFSHOTGUN"]
    },
    GangType.LOST_MC: {
        "name": "Lost MC",
        "color": "#FF0000",
        "models": ["g_m_y_lost_01", "g_m_y_lost_02", "g_m_y_lost_03"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_KNIFE", "WEAPON_SMG"]
    },
    GangType.TRIADS: {
        "name": "Triads",
        "color": "#0000FF",
        "models": ["g_m_m_chigoon_01", "g_m_m_chigoon_02", "g_m_m_chiboss_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_MICROSMG", "WEAPON_SWITCHBLADE", "WEAPON_COMBATPISTOL"]
    },
    GangType.ARMENIAN_MAFIA: {
        "name": "Armenian Mafia",
        "color": "#4B0082",
        "models": ["g_m_m_armboss_01", "g_m_m_armgoon_01", "g_m_m_armlieut_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_COMBATPISTOL", "WEAPON_ASSAULTRIFLE"]
    }
}

# NPC Models
class NPCState(str, Enum):
    IDLE = "idle"
    FOLLOWING = "following"
    ATTACKING = "attacking"
    DEFENDING = "defending"

class Formation(str, Enum):
    CIRCLE = "circle"
    LINE = "line"
    SQUARE = "square"
    SCATTERED = "scattered"

# Data Models
class NPCData(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    gang: GangType
    model: str
    position: dict  # {x, y, z}
    state: NPCState = NPCState.IDLE
    group_id: Optional[str] = None
    health: int = 100
    armor: int = 0
    accuracy: int = 50  # Mira/precisão (0-100)
    weapon: Optional[str] = None
    friendly_player_ids: List[str] = Field(default_factory=list)  # IDs do servidor
    friendly_jobs: List[str] = Field(default_factory=list)  # Jobs amigáveis
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_updated: datetime = Field(default_factory=datetime.utcnow)

class NPCSpawnRequest(BaseModel):
    gang: GangType
    model: Optional[str] = None
    position: Optional[dict] = None
    quantity: int = 1
    formation: Formation = Formation.CIRCLE
    weapon: Optional[str] = None
    health: int = 100
    armor: int = 0
    accuracy: int = 50
    friendly_player_ids: Optional[str] = ""  # String com IDs separados por vírgula
    friendly_jobs: Optional[str] = ""  # String com jobs separados por vírgula
    vec3_input: Optional[str] = ""  # Campo para colar vec3

class NPCUpdateRequest(BaseModel):
    health: Optional[int] = None
    armor: Optional[int] = None
    accuracy: Optional[int] = None
    weapon: Optional[str] = None
    friendly_player_ids: Optional[str] = ""
    friendly_jobs: Optional[str] = ""
    state: Optional[NPCState] = None

class NPCCommand(BaseModel):
    npc_id: str
    command: str  # follow, stay, attack, defend
    target_id: Optional[str] = None
    position: Optional[dict] = None

class GroupCommand(BaseModel):
    group_id: str
    command: str
    target_id: Optional[str] = None
    position: Optional[dict] = None

class ServerStats(BaseModel):
    total_npcs: int
    active_groups: int
    gang_distribution: dict
    server_performance: dict

# Utility functions
def parse_comma_separated_string(input_str: str) -> List[str]:
    """Parse string separada por vírgulas e retorna lista limpa"""
    if not input_str or not input_str.strip():
        return []
    return [item.strip() for item in input_str.split(",") if item.strip()]

def parse_vec3(vec3_str: str) -> dict:
    """Parse vec3 de qualquer formato para dict {x, y, z}"""
    if not vec3_str or not vec3_str.strip():
        return {"x": 0, "y": 0, "z": 0}
    
    # Remove espaços e converte para lowercase
    cleaned = vec3_str.strip().lower()
    
    # Extrai números (incluindo negativos e decimais) - versão melhorada
    numbers = re.findall(r'-?\d+(?:\.\d+)?', cleaned)
    
    if len(numbers) >= 3:
        try:
            return {
                "x": float(numbers[0]),
                "y": float(numbers[1]),
                "z": float(numbers[2])
            }
        except ValueError:
            pass
    
    return {"x": 0, "y": 0, "z": 0}

# API Endpoints
@api_router.get("/")
async def root():
    return {"message": "Gang NPC Manager API", "status": "online", "version": "2.0.0"}

@api_router.get("/gangs", response_model=dict)
async def get_gang_configs():
    """Retorna todas as configurações de gangues disponíveis"""
    return GANG_CONFIG

@api_router.post("/npc/spawn", response_model=List[NPCData])
async def spawn_npcs(request: NPCSpawnRequest):
    """Spawna NPCs individuais ou em grupos"""
    if request.quantity < 1 or request.quantity > 20:
        raise HTTPException(status_code=400, detail="Quantidade deve ser entre 1 e 20")
    
    if request.health < 1 or request.health > 200:
        raise HTTPException(status_code=400, detail="Vida deve ser entre 1 e 200")
    
    if request.armor < 0 or request.armor > 100:
        raise HTTPException(status_code=400, detail="Armadura deve ser entre 0 e 100")
    
    if request.accuracy < 0 or request.accuracy > 100:
        raise HTTPException(status_code=400, detail="Mira deve ser entre 0 e 100")
    
    gang_config = GANG_CONFIG[request.gang]
    
    # Seleciona modelo se não especificado
    if not request.model:
        request.model = gang_config["models"][0]
    elif request.model not in gang_config["models"]:
        raise HTTPException(status_code=400, detail="Modelo inválido para esta gangue")
    
    # Seleciona arma se não especificada
    if not request.weapon:
        request.weapon = gang_config["weapons"][0]
    elif request.weapon not in gang_config["weapons"]:
        raise HTTPException(status_code=400, detail="Arma inválida para esta gangue")
    
    # Parse vec3 se fornecido, senão usa position
    if request.vec3_input and request.vec3_input.strip():
        parsed_position = parse_vec3(request.vec3_input)
        if parsed_position["x"] == 0 and parsed_position["y"] == 0 and parsed_position["z"] == 0:
            # Se não conseguiu fazer parse do vec3, usa position original
            position = request.position
        else:
            position = parsed_position
    else:
        position = request.position
    
    # Parse amigáveis
    friendly_player_ids = parse_comma_separated_string(request.friendly_player_ids or "")
    friendly_jobs = parse_comma_separated_string(request.friendly_jobs or "")
    
    spawned_npcs = []
    group_id = str(uuid.uuid4()) if request.quantity > 1 else None
    
    for i in range(request.quantity):
        # Calcula posição baseada na formação
        calculated_position = calculate_formation_position(position, i, request.formation, request.quantity)
        
        npc = NPCData(
            gang=request.gang,
            model=request.model,
            position=calculated_position,
            group_id=group_id,
            weapon=request.weapon,
            health=request.health,
            armor=request.armor,
            accuracy=request.accuracy,
            friendly_player_ids=friendly_player_ids,
            friendly_jobs=friendly_jobs
        )
        
        # Salva no banco
        await db.npcs.insert_one(npc.dict())
        spawned_npcs.append(npc)
    
    return spawned_npcs

@api_router.get("/npcs", response_model=List[NPCData])
async def get_all_npcs():
    """Retorna todos os NPCs ativos"""
    npcs = await db.npcs.find().to_list(1000)
    return [NPCData(**npc) for npc in npcs]

@api_router.get("/npcs/{npc_id}", response_model=NPCData)
async def get_npc(npc_id: str):
    """Retorna dados de um NPC específico"""
    npc = await db.npcs.find_one({"id": npc_id})
    if not npc:
        raise HTTPException(status_code=404, detail="NPC não encontrado")
    return NPCData(**npc)

@api_router.put("/npcs/{npc_id}", response_model=NPCData)
async def update_npc(npc_id: str, update_data: NPCUpdateRequest):
    """Atualiza dados de um NPC específico"""
    npc = await db.npcs.find_one({"id": npc_id})
    if not npc:
        raise HTTPException(status_code=404, detail="NPC não encontrado")
    
    # Prepara dados para atualização
    update_fields = {
        "last_updated": datetime.utcnow()
    }
    
    if update_data.health is not None:
        if update_data.health < 1 or update_data.health > 200:
            raise HTTPException(status_code=400, detail="Vida deve ser entre 1 e 200")
        update_fields["health"] = update_data.health
    
    if update_data.armor is not None:
        if update_data.armor < 0 or update_data.armor > 100:
            raise HTTPException(status_code=400, detail="Armadura deve ser entre 0 e 100")
        update_fields["armor"] = update_data.armor
    
    if update_data.accuracy is not None:
        if update_data.accuracy < 0 or update_data.accuracy > 100:
            raise HTTPException(status_code=400, detail="Mira deve ser entre 0 e 100")
        update_fields["accuracy"] = update_data.accuracy
    
    if update_data.weapon is not None:
        gang_config = GANG_CONFIG[npc["gang"]]
        if update_data.weapon not in gang_config["weapons"]:
            raise HTTPException(status_code=400, detail="Arma inválida para esta gangue")
        update_fields["weapon"] = update_data.weapon
    
    if update_data.state is not None:
        update_fields["state"] = update_data.state
    
    # Parse amigáveis se fornecidos
    if update_data.friendly_player_ids is not None:
        update_fields["friendly_player_ids"] = parse_comma_separated_string(update_data.friendly_player_ids)
    
    if update_data.friendly_jobs is not None:
        update_fields["friendly_jobs"] = parse_comma_separated_string(update_data.friendly_jobs)
    
    # Atualiza no banco
    await db.npcs.update_one({"id": npc_id}, {"$set": update_fields})
    
    # Retorna NPC atualizado
    updated_npc = await db.npcs.find_one({"id": npc_id})
    return NPCData(**updated_npc)

@api_router.post("/npc/command")
async def send_npc_command(command: NPCCommand):
    """Envia comando para um NPC específico"""
    npc = await db.npcs.find_one({"id": command.npc_id})
    if not npc:
        raise HTTPException(status_code=404, detail="NPC não encontrado")
    
    # Atualiza estado do NPC
    update_data = {
        "last_updated": datetime.utcnow()
    }
    
    if command.command == "follow":
        update_data["state"] = NPCState.FOLLOWING
    elif command.command == "stay":
        update_data["state"] = NPCState.IDLE
    elif command.command == "attack":
        update_data["state"] = NPCState.ATTACKING
    elif command.command == "defend":
        update_data["state"] = NPCState.DEFENDING
    
    if command.position:
        update_data["position"] = command.position
    
    await db.npcs.update_one({"id": command.npc_id}, {"$set": update_data})
    
    return {"message": f"Comando '{command.command}' enviado para NPC {command.npc_id}"}

@api_router.post("/group/command")
async def send_group_command(command: GroupCommand):
    """Envia comando para um grupo de NPCs"""
    npcs = await db.npcs.find({"group_id": command.group_id}).to_list(100)
    if not npcs:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    
    # Atualiza estado de todos os NPCs do grupo
    update_data = {
        "last_updated": datetime.utcnow()
    }
    
    if command.command == "follow":
        update_data["state"] = NPCState.FOLLOWING
    elif command.command == "stay":
        update_data["state"] = NPCState.IDLE
    elif command.command == "attack":
        update_data["state"] = NPCState.ATTACKING
    elif command.command == "defend":
        update_data["state"] = NPCState.DEFENDING
    
    await db.npcs.update_many({"group_id": command.group_id}, {"$set": update_data})
    
    return {"message": f"Comando '{command.command}' enviado para grupo {command.group_id} ({len(npcs)} NPCs)"}

@api_router.delete("/npc/{npc_id}")
async def delete_npc(npc_id: str):
    """Remove um NPC específico"""
    result = await db.npcs.delete_one({"id": npc_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="NPC não encontrado")
    
    return {"message": f"NPC {npc_id} removido"}

@api_router.delete("/npcs/clear")
async def clear_all_npcs():
    """Remove todos os NPCs"""
    result = await db.npcs.delete_many({})
    return {"message": f"{result.deleted_count} NPCs removidos"}

@api_router.delete("/group/{group_id}")
async def delete_group(group_id: str):
    """Remove um grupo inteiro de NPCs"""
    result = await db.npcs.delete_many({"group_id": group_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    
    return {"message": f"Grupo {group_id} removido ({result.deleted_count} NPCs)"}

@api_router.get("/stats", response_model=ServerStats)
async def get_server_stats():
    """Retorna estatísticas do servidor"""
    total_npcs = await db.npcs.count_documents({})
    
    # Contagem por gangue
    gang_pipeline = [
        {"$group": {"_id": "$gang", "count": {"$sum": 1}}}
    ]
    gang_stats = await db.npcs.aggregate(gang_pipeline).to_list(100)
    gang_distribution = {stat["_id"]: stat["count"] for stat in gang_stats}
    
    # Contagem de grupos
    group_pipeline = [
        {"$match": {"group_id": {"$ne": None}}},
        {"$group": {"_id": "$group_id"}}
    ]
    groups = await db.npcs.aggregate(group_pipeline).to_list(100)
    active_groups = len(groups)
    
    return ServerStats(
        total_npcs=total_npcs,
        active_groups=active_groups,
        gang_distribution=gang_distribution,
        server_performance={"memory_usage": "N/A", "cpu_usage": "N/A"}
    )

@api_router.get("/groups")
async def get_groups():
    """Retorna todos os grupos ativos"""
    pipeline = [
        {"$match": {"group_id": {"$ne": None}}},
        {"$group": {
            "_id": "$group_id",
            "gang": {"$first": "$gang"},
            "count": {"$sum": 1},
            "created_at": {"$min": "$created_at"}
        }}
    ]
    groups = await db.npcs.aggregate(pipeline).to_list(100)
    return groups

def calculate_formation_position(center_pos: dict, index: int, formation: Formation, total: int) -> dict:
    """Calcula posição baseada na formação"""
    import math
    
    x, y, z = center_pos["x"], center_pos["y"], center_pos["z"]
    
    if formation == Formation.CIRCLE:
        angle = (2 * math.pi * index) / total
        radius = 2.0
        return {
            "x": x + radius * math.cos(angle),
            "y": y + radius * math.sin(angle),
            "z": z
        }
    elif formation == Formation.LINE:
        spacing = 2.0
        return {
            "x": x + (index - total/2) * spacing,
            "y": y,
            "z": z
        }
    elif formation == Formation.SQUARE:
        side = math.ceil(math.sqrt(total))
        row = index // side
        col = index % side
        spacing = 2.0
        return {
            "x": x + (col - side/2) * spacing,
            "y": y + (row - side/2) * spacing,
            "z": z
        }
    else:  # SCATTERED
        import random
        return {
            "x": x + random.uniform(-5, 5),
            "y": y + random.uniform(-5, 5),
            "z": z
        }

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
