/// Deterministic real-time combat rules for 60 Adventure stages.
/// This engine is exclusive to Adventure; Classic game rules remain untouched.
enum CombatMove { sword, power, ultimate, shield }

class AdventureCombat {
  AdventureCombat(this.level)
      : assert(level >= 1 && level <= 60),
        bossMaxHp = 960 + (level - 1) * 95 + (level % 10 == 0 ? 850 : 0),
        bossHp = 960 + (level - 1) * 95 + (level % 10 == 0 ? 850 : 0);
  final int level;
  final int bossMaxHp;
  int bossHp;
  int playerHp = 1000;
  int energy = 35;
  int shieldMs = 0, burnMs = 0, poisonMs = 0, slowMs = 0;
  int lane = 1, dangerLane = -1, warningMs = 0;
  int timeMs = 0, attacks = 0, hitsTaken = 0, damageDone = 0, bossStrikes = 0;
  int _attackWaitMs = 3300, _poisonTickMs = 900, _burnTickMs = 900;
  int _swordCooldownMs = 0, _powerCooldownMs = 0;
  int _ultimateCooldownMs = 0, _shieldCooldownMs = 0;
  int get world => (level - 1) ~/ 10;
  bool get won => bossHp <= 0 && playerHp > 0;
  bool get lost => playerHp <= 0;
  bool get finished => won || lost;
  double get bossFraction => (bossHp / bossMaxHp).clamp(0.0, 1.0);
  double get heroFraction => (playerHp / 1000).clamp(0.0, 1.0);
  int get score => damageDone + (won ? 500 + level * 30 : 0);
  int get stars {
    if (!won) return 0;
    if (playerHp >= 720 && hitsTaken <= 2) return 3;
    return playerHp >= 360 ? 2 : 1;
  }
  int cooldown(CombatMove move) => switch (move) {
    CombatMove.sword => _swordCooldownMs,
    CombatMove.power => _powerCooldownMs,
    CombatMove.ultimate => _ultimateCooldownMs,
    CombatMove.shield => _shieldCooldownMs,
  };
  bool canUse(CombatMove move) {
    if (finished || cooldown(move) > 0) return false;
    return energy >= switch (move) {
      CombatMove.sword => 0, CombatMove.power => 25,
      CombatMove.ultimate => 60, CombatMove.shield => 18,
    };
  }
  bool use(CombatMove move) {
    if (!canUse(move)) return false;
    attacks++;
    if (move == CombatMove.sword) {
      _swordCooldownMs = slowMs > 0 ? 800 : 460;
      _deal(80 + world * 9);
      energy = (energy + 10).clamp(0, 100).toInt();
    } else if (move == CombatMove.power) {
      energy -= 25;
      _powerCooldownMs = 4200;
      _deal(245 + world * 35);
    } else if (move == CombatMove.ultimate) {
      energy -= 60;
      _ultimateCooldownMs = 9400;
      _deal(620 + world * 68);
    } else if (move == CombatMove.shield) {
      energy -= 18;
      _shieldCooldownMs = 6000;
      shieldMs = 3200;
    }
    return true;
  }
  void _deal(int damage) {
    if (finished) return;
    if (world == 4 && damage < 100) damage = (damage * .85).round();
    final applied = damage.clamp(0, bossHp).toInt();
    bossHp -= applied;
    damageDone += applied;
    if (bossHp == 0) {
      warningMs = 0;
      dangerLane = -1;
    }
  }
  void move(int direction) {
    if (finished || direction == 0) return;
    lane = (lane + direction.sign).clamp(0, 2).toInt();
  }
  void tick(int deltaMs) {
    if (finished || deltaMs <= 0) return;
    final dt = deltaMs.clamp(0, 150).toInt();
    timeMs += dt;
    _swordCooldownMs = (_swordCooldownMs - dt).clamp(0, 99999).toInt();
    _powerCooldownMs = (_powerCooldownMs - dt).clamp(0, 99999).toInt();
    _ultimateCooldownMs = (_ultimateCooldownMs - dt).clamp(0, 99999).toInt();
    _shieldCooldownMs = (_shieldCooldownMs - dt).clamp(0, 99999).toInt();
    shieldMs = (shieldMs - dt).clamp(0, 99999).toInt();
    slowMs = (slowMs - dt).clamp(0, 99999).toInt();
    if (poisonMs > 0) {
      poisonMs = (poisonMs - dt).clamp(0, 99999).toInt();
      _poisonTickMs -= dt;
      if (_poisonTickMs <= 0) {
        playerHp = (playerHp - 18).clamp(0, 1000).toInt();
        _poisonTickMs = 900;
      }
    }
    if (burnMs > 0) {
      burnMs = (burnMs - dt).clamp(0, 99999).toInt();
      _burnTickMs -= dt;
      if (_burnTickMs <= 0) {
        playerHp = (playerHp - 22).clamp(0, 1000).toInt();
        _burnTickMs = 900;
      }
    }
    if (lost) return;
    if (warningMs > 0) {
      warningMs -= dt;
      if (warningMs <= 0) {
        _strike();
        dangerLane = -1;
        warningMs = 0;
        _attackWaitMs = (2700 - world * 150).clamp(1700, 2700).toInt();
      }
      return;
    }
    _attackWaitMs -= dt;
    if (_attackWaitMs <= 0) {
      bossStrikes++;
      dangerLane = (bossStrikes + level) % 3;
      warningMs = (1450 - world * 65).clamp(980, 1450).toInt();
    }
  }
  void _strike() {
    final inRange = lane == dangerLane ||
        (world == 1 && (lane - dangerLane).abs() == 1 && bossStrikes.isEven);
    if (!inRange) return;
    if (shieldMs > 0) {
      shieldMs = 0;
      return;
    }
    final damage = 100 + world * 26 + (level % 10) * 5;
    playerHp = (playerHp - damage).clamp(0, 1000).toInt();
    hitsTaken++;
    if (world == 1) {
      slowMs = 2400;
    } else if (world == 2) {
      poisonMs = 2800;
    } else if (world == 3) {
      burnMs = 2800;
    } else if (world == 4) {
      energy = (energy - 10).clamp(0, 100).toInt();
    } else if (world == 5) {
      bossHp = (bossHp + 36).clamp(0, bossMaxHp).toInt();
    }
  }
}