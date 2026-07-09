// Standalone verification for RewardTableConfig.PickWeighted's odds.
//
// No Luau runtime was available in the environment this was written in, so
// this does NOT execute the real .luau file — it parses the actual weight
// table straight out of ../src/shared/Config/RewardTableConfig.luau (so the
// numbers can't drift from what's actually configured) and reimplements the
// same cumulative-weight walk as PickWeighted, line for line, in JS. Run
// `node tests/verify_weighted_rng.js` after any change to the reward table
// or the picking logic to regenerate results.log.

const fs = require("fs");
const path = require("path");

const configPath = path.join(__dirname, "..", "src", "shared", "Config", "RewardTableConfig.luau");
const source = fs.readFileSync(configPath, "utf8");

const rowPattern = /Id\s*=\s*"([^"]+)".*?Rarity\s*=\s*"([^"]+)".*?Weight\s*=\s*(\d+).*?CoinAmount\s*=\s*(\d+)/g;
const rewards = [];
let match;
while ((match = rowPattern.exec(source)) !== null) {
  rewards.push({
    id: match[1],
    rarity: match[2],
    weight: Number(match[3]),
    coinAmount: Number(match[4]),
  });
}

if (rewards.length === 0) {
  console.error("Failed to parse any reward rows out of RewardTableConfig.luau — has the format changed?");
  process.exit(1);
}

const totalWeight = rewards.reduce((sum, r) => sum + r.weight, 0);

// Mirrors RewardTableConfig.PickWeighted exactly: walk the cumulative
// weight and return the first entry the roll falls under.
function pickWeighted(roll) {
  let cumulative = 0;
  for (const reward of rewards) {
    cumulative += reward.weight;
    if (roll < cumulative) {
      return reward;
    }
  }
  return rewards[rewards.length - 1];
}

console.log("Parsed reward table from RewardTableConfig.luau:");
for (const r of rewards) {
  console.log(`  ${r.rarity.padEnd(10)} weight=${r.weight} -> ${(100 * r.weight / totalWeight).toFixed(2)}% expected`);
}
console.log(`Total weight: ${totalWeight}\n`);

// --- Edge cases, mirroring RewardRollService: roll = Random:NextNumber() * totalWeight, range [0, totalWeight) ---
console.log("Edge cases:");
console.log(`  roll = 0                -> ${pickWeighted(0).rarity} (expect first entry, ${rewards[0].rarity})`);
console.log(`  roll = totalWeight - 1e-9 -> ${pickWeighted(totalWeight - 1e-9).rarity} (expect last entry, ${rewards[rewards.length - 1].rarity})`);
console.log(`  roll = totalWeight (out of range) -> ${pickWeighted(totalWeight).rarity} (fallback path, expect last entry)`);
console.log("");

// --- Bulk simulation ---
const TRIALS = 100000;
const counts = Object.fromEntries(rewards.map((r) => [r.rarity, 0]));

for (let i = 0; i < TRIALS; i++) {
  const roll = Math.random() * totalWeight; // mirrors Random:NextNumber() * totalWeight
  const reward = pickWeighted(roll);
  counts[reward.rarity]++;
}

console.log(`Simulated ${TRIALS} rolls:`);
let maxDeviation = 0;
for (const r of rewards) {
  const actualPct = (100 * counts[r.rarity]) / TRIALS;
  const expectedPct = (100 * r.weight) / totalWeight;
  const deviation = Math.abs(actualPct - expectedPct);
  maxDeviation = Math.max(maxDeviation, deviation);
  console.log(
    `  ${r.rarity.padEnd(10)} expected=${expectedPct.toFixed(2)}%  actual=${actualPct.toFixed(2)}%  count=${counts[r.rarity]}  deviation=${deviation.toFixed(3)}pp`
  );
}
console.log(`\nMax deviation from expected odds: ${maxDeviation.toFixed(3)} percentage points over ${TRIALS} trials.`);
