import items;
import includes_for_shortcut;

alias s8  = byte;
alias s16 = short;
alias s32 = int;
alias s64 = long;
alias u8  = ubyte;
alias u16 = ushort;
alias u32 = uint;
alias u64 = ulong;

struct MainData {
  u8[0x136] unk_0x00;
  bool runHeld;
  bool aJustPressed;
  u8[0x144-0x138] unk_0x138;
  bool bJustPressed;
  u8[0x7FC-0x145] unk_0x145;
  u32 loc_0x7FC;
}

struct MenuData {

}

struct Inventory {
  u8[0x220A] unk_0x00;
  ItemId equippedEquipment;
}

struct InventorySub {

}

enum PlayerEquipSlot {
  _0,
  _1,
  shirt,
  accessory,
  headgear,
  equipment,
  helmet,
  _7,
  _8,
}

enum Equipment : ubyte {
  none,

  // Tools
  shovel,
  golden_shovel,
  axe_new,
  axe_wear_level_1,
  axe_wear_level_2,
  axe_wear_level_3,
  axe_wear_level_4,
  axe_wear_level_5,
  axe_wear_level_6,
  axe_worn,
  golden_axe,
  fishing_rod,
  golden_rod,
  net,
  golden_net,
  watering_can,
  golden_can,
  slingshot,
  golden_slingshot,

  // Held Items
  dandelion_puffs,
  party_popper,
  sparkler,
  roman_candle,

  // Umbrellas
  gelato_umbrella,
  bat_umbrella,
  lacy_parasol,
  leaf_umbrella,
  paper_parasol,
  ribbon_umbrella,
  red_umbrella,
  blue_umbrella,
  yellow_umbrella,
  green_umbrella,
  candy_umbrella,
  melon_umbrella,
  mint_umbrella,
  picnic_umbrella,
  lemon_umbrella,
  toad_parasol,
  eggy_parasol,
  blue_dot_parasol,
  daisy_umbrella,
  paw_umbrella,
  petal_parasol,
  busted_umbrella,
  sunny_parasol,
  beach_umbrella,
  elegant_umbrella,
  modern_umbrella,
  leopard_umbrella,
  zebra_umbrella,
  forest_umbrella,
  flame_umbrella,
  camo_umbrella,
  spider_umbrella,
  custom_umbrella_1,
  custom_umbrella_2,
  custom_umbrella_3,
  custom_umbrella_4,
  custom_umbrella_5,
  custom_umbrella_6,
  custom_umbrella_7,
  custom_umbrella_8,
}

enum InventorySlot : ubyte {
  item_first, item_2, item_3, item_4, item_5, item_6, item_7, item_8, item_9, item_10, item_11, item_12, item_13, item_14, item_last,
  letter_first, letter_2, letter_3, letter_4, letter_5, letter_6, letter_7, letter_8, letter_9, letter_last
}

enum NUM_ITEM_SLOTS   = 15;
enum NUM_LETTER_SLOTS = 10;
enum INVENTORY_SIZE   = NUM_ITEM_SLOTS + NUM_LETTER_SLOTS;

enum InstructionSet {
  arm   = 0,
  thumb = 1
}

mixin template FUNC(string name, size_t location, InstructionSet instructionSet, FuncType) {
  mixin("__gshared immutable extern(C) FuncType " ~ name ~ " = cast(FuncType) (location + instructionSet);");
}

mixin FUNC!("ChangePlayerEquipment", 0x02094a3c, InstructionSet.thumb, bool function(Equipment, u32));
mixin FUNC!("GetInventoryObject",    0x02097844, InstructionSet.thumb, Inventory* function());
mixin FUNC!("GetInventoryItemList",  0x020982b8, InstructionSet.thumb, ItemId[INVENTORY_SIZE]* function(InventorySub*, size_t));
mixin FUNC!("GetPlayerEquipment",    0x02098a90, InstructionSet.thumb, ItemId* function(Inventory* inventory));
mixin FUNC!("GetInventorySub",       0x02098a9c, InstructionSet.thumb, InventorySub* function(Inventory* inventory));
mixin FUNC!("SetPlayerEquipment",    0x02098a84, InstructionSet.thumb, void function(Inventory*, ItemId*));
//mixin FUNC!("SwapOutEquippedSlot",   0x02296830, InstructionSet.thumb, void function(ItemId, MenuData*, PlayerEquipSlot, ItemId));

struct FreeRam {
  ItemId lastTool;
}

enum Button : ushort {
  a      = 1 << 0,
  b      = 1 << 1,
  select = 1 << 2,
  start  = 1 << 3,
  right  = 1 << 4,
  left   = 1 << 5,
  up     = 1 << 6,
  down   = 1 << 7,
  r      = 1 << 8,
  l      = 1 << 9,
  y      = 1 << 10,
  x      = 1 << 11,
}

enum Button* gInputHeld = cast(Button*) 0x021f7e80;
enum Button* gInputDown = cast(Button*) 0x021f7e82;

extern(C) void shortcuts(MainData* mainData) {
  FreeRam* freeRam = cast(FreeRam*) Mod_Free_RAM;

  auto held = *gInputHeld;
  auto down = *gInputDown;

  if (!(held & Button.l)) return;
  if (!(down & (Button.down | Button.left | Button.right))) return;

  auto inventory         = GetInventoryObject();
  auto inventorySub      = GetInventorySub(inventory);
  auto inventoryItemList = GetInventoryItemList(inventorySub, 0);

  auto equipment = GetPlayerEquipment(inventory);

  // Down: place current tool back in inventory
  if ((down & Button.down)) {
    if (!equipment || *equipment == ItemId.empty) return;

    ItemId* freeSlot;
    foreach (i; InventorySlot.item_first..InventorySlot.item_last+1) {
      if ((*inventoryItemList)[i] == ItemId.empty) {
        freeSlot = &(*inventoryItemList)[i];
        break;
      }
    }

    if (!freeSlot) return;

    *freeSlot        = *equipment;
    freeRam.lastTool = *equipment;
    ChangePlayerEquipment(Equipment.none, mainData.loc_0x7FC);
  }
  // Left/Right: cycle through tools
  else if ((down & (Button.left | Button.right))) {
    int scrollDir = (down & Button.left) ? -1 : 1;

    ItemId oldEquip = *equipment;
    ItemId bestChoice;
    InventorySlot bestChoiceSlot;
    int bestChoiceIdDist = 0x10000;
    bool triedToolIdWrapAround = false;

    // Handle first use since startup when hand is empty
    if (freeRam.lastTool == 0) {
      freeRam.lastTool = ItemId.equipment_first;
    }

    // If hand is empty, always search for the last tool scrolled to or removed
    if (oldEquip == ItemId.empty) {
      oldEquip = cast(ItemId) (freeRam.lastTool - 1);
      scrollDir = 1;
    }

    bool foundItem = false;

    // Search for the next highest or lowest tool ID in the inventory, wrapping around
    foreach (cursor; InventorySlot.item_first..InventorySlot.item_last+1) {
      auto item = (*inventoryItemList)[cursor];
      if (item == oldEquip) continue;

      int idDist = (scrollDir == 1) ? item - oldEquip : oldEquip - item;
      if (idDist < 0) idDist += (ItemId.equipment_last - ItemId.equipment_first + 1);

      if (item >= ItemId.equipment_first && item <= ItemId.equipment_last && idDist < bestChoiceIdDist) {
        foundItem        = true;
        bestChoice       = item;
        bestChoiceIdDist = idDist;
        bestChoiceSlot   = cast(InventorySlot) cursor;
      }
    }

    if (foundItem) {
      (*inventoryItemList)[bestChoiceSlot] = *equipment;
      ChangePlayerEquipment(toEquipment(bestChoice), mainData.loc_0x7FC);
      freeRam.lastTool = bestChoice;
    }
  }
}

pragma(inline, true)
Equipment toEquipment(ItemId item) {
  // Assumes item actually maps to an equipment
  return cast(Equipment) (item - ItemId.tool_first + 1);
}