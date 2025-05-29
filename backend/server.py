from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List, Optional, Union
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
app = FastAPI(title="Gang NPC Manager API v2.0", description="Sistema avançado de gerenciamento de NPCs para FiveM")

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
        "weapons": ["WEAPON_PISTOL", "WEAPON_MICROSMG", "WEAPON_MACHETE", "WEAPON_PUMPSHOTGUN", "WEAPON_SMG"]
    },
    GangType.GROVE_STREET: {
        "name": "Grove Street Families",
        "color": "#00FF00",
        "models": ["g_m_y_famca_01", "g_m_y_famdnf_01", "g_m_y_famfor_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_KNIFE", "WEAPON_ASSAULTRIFLE", "WEAPON_COMBATPISTOL"]
    },
    GangType.VAGOS: {
        "name": "Los Santos Vagos",
        "color": "#FFFF00",
        "models": ["g_m_y_mexgang_01", "g_m_y_mexgoon_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_MICROSMG", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_SMG"]
    },
    GangType.LOST_MC: {
        "name": "Lost MC",
        "color": "#FF0000",
        "models": ["g_m_y_lost_01", "g_m_y_lost_02", "g_m_y_lost_03"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_KNIFE", "WEAPON_SMG", "WEAPON_ASSAULTRIFLE"]
    },
    GangType.TRIADS: {
        "name": "Triads",
        "color": "#0000FF",
        "models": ["g_m_m_chigoon_01", "g_m_m_chigoon_02", "g_m_m_chiboss_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_MICROSMG", "WEAPON_SWITCHBLADE", "WEAPON_COMBATPISTOL", "WEAPON_SMG"]
    },
    GangType.ARMENIAN_MAFIA: {
        "name": "Armenian Mafia",
        "color": "#4B0082",
        "models": ["g_m_m_armboss_01", "g_m_m_armgoon_01", "g_m_m_armlieut_01"],
        "weapons": ["WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_COMBATPISTOL", "WEAPON_ASSAULTRIFLE", "WEAPON_PUMPSHOTGUN"]
    }
}

# NPC Models
class NPCState(str, Enum):
    IDLE = "idle"
    FOLLOWING = "following"
    ATTACKING = "attacking"
    DEFENDING = "defending"
    GUARDING = "guarding"
    PEACEFUL = "peaceful"
    COMBAT = "combat"

class Formation(str, Enum):
    CIRCLE = "circle"
    LINE = "line"
    SQUARE = "square"
    SCATTERED = "scattered"

class GroupRole(str, Enum):
    OWNER = "owner"
    LEADER = "leader"
    FRIENDLY = "friendly"
    NEUTRAL = "neutral"
    ENEMY = "enemy"

class TargetType(str, Enum):
    PLAYER_ID = "player_id"
    JOB = "job"
    GANG = "gang"
    ALL = "all"
    POSITION = "position"

# Advanced Group System
class GroupMember(BaseModel):
    type: TargetType  # player_id, job, gang, all
    value: str  # ID, job name, gang name, "all"
    role: GroupRole  # owner, leader, friendly, neutral, enemy

class NPCGroup(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = ""
    gang: GangType
    members: List[GroupMember] = Field(default_factory=list)
    auto_defend: bool = True  # Defend owners/leaders automatically
    auto_attack_enemies: bool = True  # Attack enemies on sight
    patrol_area: Optional[dict] = None  # {center: {x,y,z}, radius: float}
    created_by: Optional[str] = None  # Admin who created
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_updated: datetime = Field(default_factory=datetime.utcnow)

# Enhanced NPC Data
class NPCData(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    gang: GangType
    model: str
    position: dict  # {x, y, z}
    heading: float = 0.0
    state: NPCState = NPCState.IDLE
    group_id: Optional[str] = None
    npc_group_id: Optional[str] = None  # Advanced group system
    health: int = 100
    armor: int = 0
    accuracy: int = 50
    weapon: Optional[str] = None
    
    # Individual permissions (legacy)
    friendly_player_ids: List[str] = Field(default_factory=list)
    friendly_jobs: List[str] = Field(default_factory=list)
    
    # Advanced permissions (new)
    owner_ids: List[str] = Field(default_factory=list)  # Can control this NPC
    
    # AI Behavior
    patrol_route: List[dict] = Field(default_factory=list)  # [{x,y,z}, ...]
    guard_position: Optional[dict] = None  # {x,y,z} to defend
    target_id: Optional[str] = None  # Current target player ID
    target_position: Optional[dict] = None  # Current target position
    
    # Status
    last_command: Optional[str] = None
    last_command_by: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_updated: datetime = Field(default_factory=datetime.utcnow)

class NPCSpawnRequest(BaseModel):
    gang: GangType
    model: Optional[str] = None
    position: Optional[dict] = None
    heading: float = 0.0
    quantity: int = 1
    formation: Formation = Formation.CIRCLE
    weapon: Optional[str] = None
    health: int = 100
    armor: int = 0
    accuracy: int = 50
    
    # Permissions
    owner_ids: Optional[str] = ""  # String with IDs separated by comma
    friendly_player_ids: Optional[str] = ""
    friendly_jobs: Optional[str] = ""
    npc_group_id: Optional[str] = None  # Assign to advanced group
    
    # Convenience
    vec3_input: Optional[str] = ""

class NPCUpdateRequest(BaseModel):
    health: Optional[int] = None
    armor: Optional[int] = None
    accuracy: Optional[int] = None
    weapon: Optional[str] = None
    heading: Optional[float] = None
    owner_ids: Optional[str] = ""
    friendly_player_ids: Optional[str] = ""
    friendly_jobs: Optional[str] = ""
    npc_group_id: Optional[str] = None
    state: Optional[NPCState] = None
    guard_position: Optional[dict] = None

class NPCCommand(BaseModel):
    npc_id: str
    command: str  # follow, stay, attack, defend, guard, peaceful, combat
    issued_by: str  # Player ID issuing command
    target_id: Optional[str] = None  # Target player ID
    position: Optional[dict] = None  # Target position
    patrol_route: Optional[List[dict]] = None  # For patrol command

class GroupCommand(BaseModel):
    group_id: str  # Can be spawn group or advanced group
    command: str
    issued_by: str
    target_id: Optional[str] = None
    position: Optional[dict] = None

class GroupCreateRequest(BaseModel):
    name: str
    description: Optional[str] = ""
    gang: GangType
    created_by: str
    members: List[GroupMember] = Field(default_factory=list)
    auto_defend: bool = True
    auto_attack_enemies: bool = True
    patrol_area: Optional[dict] = None

class ServerStats(BaseModel):
    total_npcs: int
    active_spawn_groups: int
    active_npc_groups: int
    gang_distribution: dict
    group_distribution: dict
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
    
    # Remove prefixos como "vec3" e converte para lowercase
    cleaned = vec3_str.strip().lower()
    
    # Remove "vec3(" do início se existir
    if cleaned.startswith('vec3'):
        cleaned = cleaned[4:]  # Remove "vec3"
    
    # Extrai números (incluindo negativos e decimais)
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

def can_control_npc(npc: NPCData, player_id: str) -> tuple[bool, str]:
    """Check if player can control NPC and return permission level"""
    player_id = str(player_id)
    
    # Check owner permissions (highest level)
    if player_id in npc.owner_ids:
        return True, "owner"
    
    # Check friendly permissions (basic level)
    if player_id in npc.friendly_player_ids:
        return True, "friendly"
    
    # TODO: Check advanced group permissions
    if npc.npc_group_id:
        # This would check group membership
        pass
    
    return False, "unauthorized"

async def get_npc_group_permissions(group_id: str, player_id: str) -> tuple[bool, str]:
    """Check if player has permissions in advanced group"""
    group = await db.npc_groups.find_one({"id": group_id})
    if not group:
        return False, "group_not_found"
    
    player_id = str(player_id)
    
    for member in group.get("members", []):
        if member["type"] == "player_id" and member["value"] == player_id:
            return True, member["role"]
        elif member["type"] == "all" and member["value"] == "all":
            return True, member["role"]
        # TODO: Add job/gang checks
    
    return False, "not_member"

# API Endpoints
@api_router.get("/")
async def root():
    return {"message": "Gang NPC Manager API v2.0", "status": "online", "version": "2.0.0"}

@api_router.get("/gangs", response_model=dict)
async def get_gang_configs():
    """Retorna todas as configurações de gangues disponíveis"""
    return GANG_CONFIG

# NPC Management
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
            position = request.position or {"x": 0, "y": 0, "z": 0}
        else:
            position = parsed_position
    else:
        position = request.position or {"x": 0, "y": 0, "z": 0}
    
    # Parse permissions
    owner_ids = parse_comma_separated_string(request.owner_ids or "")
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
            heading=request.heading,
            group_id=group_id,
            npc_group_id=request.npc_group_id,
            weapon=request.weapon,
            health=request.health,
            armor=request.armor,
            accuracy=request.accuracy,
            owner_ids=owner_ids,
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
    
    if update_data.heading is not None:
        update_fields["heading"] = update_data.heading
    
    if update_data.weapon is not None:
        gang_config = GANG_CONFIG[npc["gang"]]
        if update_data.weapon not in gang_config["weapons"]:
            raise HTTPException(status_code=400, detail="Arma inválida para esta gangue")
        update_fields["weapon"] = update_data.weapon
    
    if update_data.state is not None:
        update_fields["state"] = update_data.state
    
    if update_data.guard_position is not None:
        update_fields["guard_position"] = update_data.guard_position
    
    if update_data.npc_group_id is not None:
        update_fields["npc_group_id"] = update_data.npc_group_id
    
    # Parse permissions se fornecidas
    if update_data.owner_ids is not None:
        update_fields["owner_ids"] = parse_comma_separated_string(update_data.owner_ids)
    
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
    
    npc_data = NPCData(**npc)
    
    # Check permissions
    can_control, permission_level = can_control_npc(npc_data, command.issued_by)
    if not can_control:
        raise HTTPException(status_code=403, detail="Você não tem permissão para controlar este NPC")
    
    # Atualiza estado do NPC
    update_data = {
        "last_updated": datetime.utcnow(),
        "last_command": command.command,
        "last_command_by": command.issued_by
    }
    
    if command.command == "follow":
        update_data["state"] = NPCState.FOLLOWING
        update_data["target_id"] = command.issued_by
    elif command.command == "stay":
        update_data["state"] = NPCState.IDLE
        update_data["target_id"] = None
    elif command.command == "attack":
        update_data["state"] = NPCState.ATTACKING
        if command.target_id:
            update_data["target_id"] = command.target_id
        elif command.position:
            update_data["target_position"] = command.position
    elif command.command == "defend":
        update_data["state"] = NPCState.DEFENDING
        update_data["target_id"] = command.issued_by
    elif command.command == "guard":
        update_data["state"] = NPCState.GUARDING
        if command.position:
            update_data["guard_position"] = command.position
    elif command.command == "peaceful":
        update_data["state"] = NPCState.PEACEFUL
    elif command.command == "combat":
        update_data["state"] = NPCState.COMBAT
    elif command.command == "patrol":
        update_data["state"] = NPCState.FOLLOWING
        if command.patrol_route:
            update_data["patrol_route"] = command.patrol_route
    
    await db.npcs.update_one({"id": command.npc_id}, {"$set": update_data})
    
    return {
        "message": f"Comando '{command.command}' enviado para NPC {command.npc_id}",
        "permission_level": permission_level
    }

@api_router.post("/group/command")
async def send_group_command(command: GroupCommand):
    """Envia comando para um grupo de NPCs"""
    npcs = await db.npcs.find({
        "$or": [
            {"group_id": command.group_id},
            {"npc_group_id": command.group_id}
        ]
    }).to_list(100)
    
    if not npcs:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    
    successful_commands = 0
    failed_commands = 0
    
    for npc in npcs:
        npc_data = NPCData(**npc)
        can_control, _ = can_control_npc(npc_data, command.issued_by)
        
        if can_control:
            # Apply command
            update_data = {
                "last_updated": datetime.utcnow(),
                "last_command": command.command,
                "last_command_by": command.issued_by
            }
            
            if command.command == "follow":
                update_data["state"] = NPCState.FOLLOWING
                update_data["target_id"] = command.issued_by
            elif command.command == "stay":
                update_data["state"] = NPCState.IDLE
            elif command.command == "peaceful":
                update_data["state"] = NPCState.PEACEFUL
            elif command.command == "combat":
                update_data["state"] = NPCState.COMBAT
            
            await db.npcs.update_one({"id": npc["id"]}, {"$set": update_data})
            successful_commands += 1
        else:
            failed_commands += 1
    
    return {
        "message": f"Comando '{command.command}' enviado para grupo {command.group_id}",
        "successful": successful_commands,
        "failed": failed_commands,
        "total": len(npcs)
    }

# Advanced Group Management
@api_router.post("/npc-groups", response_model=NPCGroup)
async def create_npc_group(request: GroupCreateRequest):
    """Cria um novo grupo avançado de NPCs"""
    group = NPCGroup(
        name=request.name,
        description=request.description,
        gang=request.gang,
        members=request.members,
        auto_defend=request.auto_defend,
        auto_attack_enemies=request.auto_attack_enemies,
        patrol_area=request.patrol_area,
        created_by=request.created_by
    )
    
    await db.npc_groups.insert_one(group.dict())
    return group

@api_router.get("/npc-groups", response_model=List[NPCGroup])
async def get_npc_groups():
    """Retorna todos os grupos avançados"""
    groups = await db.npc_groups.find().to_list(100)
    return [NPCGroup(**group) for group in groups]

@api_router.get("/npc-groups/{group_id}", response_model=NPCGroup)
async def get_npc_group(group_id: str):
    """Retorna um grupo específico"""
    group = await db.npc_groups.find_one({"id": group_id})
    if not group:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    return NPCGroup(**group)

@api_router.put("/npc-groups/{group_id}", response_model=NPCGroup)
async def update_npc_group(group_id: str, request: GroupCreateRequest):
    """Atualiza um grupo existente"""
    existing_group = await db.npc_groups.find_one({"id": group_id})
    if not existing_group:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    
    update_data = {
        "name": request.name,
        "description": request.description,
        "gang": request.gang,
        "members": [member.dict() for member in request.members],
        "auto_defend": request.auto_defend,
        "auto_attack_enemies": request.auto_attack_enemies,
        "patrol_area": request.patrol_area,
        "last_updated": datetime.utcnow()
    }
    
    await db.npc_groups.update_one({"id": group_id}, {"$set": update_data})
    updated_group = await db.npc_groups.find_one({"id": group_id})
    return NPCGroup(**updated_group)

@api_router.delete("/npc-groups/{group_id}")
async def delete_npc_group(group_id: str):
    """Remove um grupo avançado"""
    result = await db.npc_groups.delete_one({"id": group_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    
    # Remove group reference from NPCs
    await db.npcs.update_many(
        {"npc_group_id": group_id},
        {"$unset": {"npc_group_id": ""}}
    )
    
    return {"message": f"Grupo {group_id} removido"}

# Legacy endpoints
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
    """Remove um grupo de spawn"""
    result = await db.npcs.delete_many({"group_id": group_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Grupo não encontrado")
    
    return {"message": f"Grupo {group_id} removido ({result.deleted_count} NPCs)"}

@api_router.get("/stats", response_model=ServerStats)
async def get_server_stats():
    """Retorna estatísticas do servidor"""
    total_npcs = await db.npcs.count_documents({})
    total_npc_groups = await db.npc_groups.count_documents({})
    
    # Contagem por gangue
    gang_pipeline = [
        {"$group": {"_id": "$gang", "count": {"$sum": 1}}}
    ]
    gang_stats = await db.npcs.aggregate(gang_pipeline).to_list(100)
    gang_distribution = {stat["_id"]: stat["count"] for stat in gang_stats}
    
    # Contagem de grupos de spawn
    spawn_group_pipeline = [
        {"$match": {"group_id": {"$ne": None}}},
        {"$group": {"_id": "$group_id"}}
    ]
    spawn_groups = await db.npcs.aggregate(spawn_group_pipeline).to_list(100)
    
    # Contagem de grupos avançados
    npc_group_pipeline = [
        {"$group": {"_id": "$gang", "count": {"$sum": 1}}}
    ]
    npc_group_stats = await db.npc_groups.aggregate(npc_group_pipeline).to_list(100)
    group_distribution = {stat["_id"]: stat["count"] for stat in npc_group_stats}
    
    return ServerStats(
        total_npcs=total_npcs,
        active_spawn_groups=len(spawn_groups),
        active_npc_groups=total_npc_groups,
        gang_distribution=gang_distribution,
        group_distribution=group_distribution,
        server_performance={"memory_usage": "N/A", "cpu_usage": "N/A"}
    )

@api_router.get("/groups")
async def get_spawn_groups():
    """Retorna todos os grupos de spawn ativos"""
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

# Player Control Endpoints (for FiveM integration)
@api_router.get("/player/{player_id}/npcs")
async def get_player_npcs(player_id: str):
    """Retorna NPCs que o player pode controlar"""
    npcs = await db.npcs.find({
        "$or": [
            {"owner_ids": str(player_id)},
            {"friendly_player_ids": str(player_id)}
        ]
    }).to_list(100)
    
    result = []
    for npc in npcs:
        npc_data = NPCData(**npc)
        can_control, permission_level = can_control_npc(npc_data, player_id)
        if can_control:
            result.append({
                "npc": npc_data,
                "permission_level": permission_level
            })
    
    return result

@api_router.get("/player/{player_id}/groups")
async def get_player_groups(player_id: str):
    """Retorna grupos que o player pode controlar"""
    groups = await db.npc_groups.find({
        "members": {
            "$elemMatch": {
                "$or": [
                    {"type": "player_id", "value": str(player_id)},
                    {"type": "all", "value": "all"}
                ]
            }
        }
    }).to_list(100)
    
    result = []
    for group in groups:
        # Find permission level
        permission_level = "none"
        for member in group.get("members", []):
            if (member["type"] == "player_id" and member["value"] == str(player_id)) or \
               (member["type"] == "all" and member["value"] == "all"):
                permission_level = member["role"]
                break
        
        if permission_level != "none":
            result.append({
                "group": NPCGroup(**group),
                "permission_level": permission_level
            })
    
    return result

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
