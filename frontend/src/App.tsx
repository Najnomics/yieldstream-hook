import * as React from "react";
import { Activity, ArrowRightLeft, BadgeDollarSign, CheckCircle2, CircleDollarSign, Coins, Flame, Lock, Play, RotateCw, Wallet } from "lucide-react";
import { createPublicClient, http } from "viem";

type Step = "idle" | "deposited" | "sold" | "fees" | "settled" | "redeemed";

const rpcUrl = import.meta.env.VITE_PUBLIC_RPC_URL || "http://127.0.0.1:8545";
const chainId = Number(import.meta.env.VITE_CHAIN_ID || 31337);
const publicClient = createPublicClient({
  transport: http(rpcUrl),
});

const stepOrder: Step[] = ["idle", "deposited", "sold", "fees", "settled", "redeemed"];

function format(value: number, suffix = "") {
  return `${value.toLocaleString(undefined, { maximumFractionDigits: 2 })}${suffix}`;
}

export function App() {
  const [step, setStep] = React.useState<Step>("idle");
  const [lpCapital0, setLpCapital0] = React.useState(10);
  const [lpCapital1, setLpCapital1] = React.useState(20_000);
  const [fytSold, setFytSold] = React.useState(0);
  const [fees0, setFees0] = React.useState(0);
  const [fees1, setFees1] = React.useState(0);
  const [bobFees0, setBobFees0] = React.useState(0);
  const [bobFees1, setBobFees1] = React.useState(0);
  const [aliceRedeemed0, setAliceRedeemed0] = React.useState(0);
  const [aliceRedeemed1, setAliceRedeemed1] = React.useState(0);
  const [networkStatus, setNetworkStatus] = React.useState("demo mode");

  React.useEffect(() => {
    publicClient
      .getBlockNumber()
      .then((block) => setNetworkStatus(`rpc block ${block.toString()}`))
      .catch(() => setNetworkStatus("demo mode"));
  }, []);

  const stepIndex = stepOrder.indexOf(step);
  const fytSupply = stepIndex >= 1 ? 50_300 : 0;
  const ptSupply = stepIndex >= 1 ? 1_000 : 0;
  const epochProgress = stepIndex < 4 ? Math.min(82, 16 + stepIndex * 22) : 100;

  function reset() {
    setStep("idle");
    setFytSold(0);
    setFees0(0);
    setFees1(0);
    setBobFees0(0);
    setBobFees1(0);
    setAliceRedeemed0(0);
    setAliceRedeemed1(0);
  }

  function addLiquidity() {
    setStep("deposited");
  }

  function sellFyt() {
    setFytSold(1_500);
    setStep("sold");
  }

  function accrueFees() {
    setFees0(0.42);
    setFees1(820);
    setStep("fees");
  }

  function settle() {
    setStep("settled");
  }

  function redeem() {
    setBobFees0(fees0);
    setBobFees1(fees1);
    setAliceRedeemed0(lpCapital0);
    setAliceRedeemed1(lpCapital1);
    setStep("redeemed");
  }

  return (
    <main className="app-shell">
      <nav className="topbar">
        <div>
          <p className="eyebrow">Uniswap v4 hook</p>
          <h1>YieldStream</h1>
        </div>
        <div className="status-pill">
          <Activity size={16} />
          <span>{networkStatus}</span>
        </div>
      </nav>

      <section className="workspace">
        <aside className="sidebar">
          <div className="identity">
            <CircleDollarSign size={28} />
            <div>
              <strong>ETH / USDC</strong>
              <span>Epoch 0 · 50,400 blocks</span>
            </div>
          </div>
          <div className="meter">
            <div style={{ width: `${epochProgress}%` }} />
          </div>
          <div className="step-list">
            {[
              ["Deposit", "LP receives FYT + PT"],
              ["Transfer FYT", "Yield buyer takes fee risk"],
              ["Accrue Fees", "Hook emits FeesAccrued"],
              ["Settle", "Reactive callback closes epoch"],
              ["Redeem", "Claims are burned"],
            ].map(([label, body], index) => (
              <div className={stepIndex > index ? "step done" : stepIndex === index ? "step active" : "step"} key={label}>
                <span>{index + 1}</span>
                <div>
                  <strong>{label}</strong>
                  <small>{body}</small>
                </div>
              </div>
            ))}
          </div>
        </aside>

        <section className="main-panel">
          <div className="toolbar">
            <button onClick={addLiquidity} disabled={step !== "idle"} title="Add liquidity">
              <Wallet size={18} />
              <span>Add</span>
            </button>
            <button onClick={sellFyt} disabled={step !== "deposited"} title="Transfer FYT">
              <ArrowRightLeft size={18} />
              <span>Transfer</span>
            </button>
            <button onClick={accrueFees} disabled={step !== "sold"} title="Accrue fees">
              <Flame size={18} />
              <span>Fees</span>
            </button>
            <button onClick={settle} disabled={step !== "fees"} title="Settle epoch">
              <CheckCircle2 size={18} />
              <span>Settle</span>
            </button>
            <button onClick={redeem} disabled={step !== "settled"} title="Redeem claims">
              <BadgeDollarSign size={18} />
              <span>Redeem</span>
            </button>
            <button onClick={reset} title="Reset demo">
              <RotateCw size={18} />
            </button>
          </div>

          <div className="metrics-grid">
            <Metric icon={<Coins size={20} />} label="LP capital" value={`${format(lpCapital0)} ETH / ${format(lpCapital1)} USDC`} />
            <Metric icon={<Play size={20} />} label="FYT supply" value={format(fytSupply)} />
            <Metric icon={<Lock size={20} />} label="PT supply" value={format(ptSupply)} />
            <Metric icon={<Flame size={20} />} label="Epoch fees" value={`${format(fees0)} ETH / ${format(fees1)} USDC`} />
          </div>

          <div className="split">
            <section className="surface">
              <h2>Alice · LP seller</h2>
              <div className="balance-row">
                <span>FYT sold upfront</span>
                <strong>{format(fytSold, " USDC")}</strong>
              </div>
              <div className="balance-row">
                <span>PT redemption</span>
                <strong>{format(aliceRedeemed0, " ETH")} / {format(aliceRedeemed1, " USDC")}</strong>
              </div>
              <div className="token-strip">
                <span>PT holder</span>
                <span>{stepIndex >= 1 && step !== "redeemed" ? "active" : "closed"}</span>
              </div>
            </section>

            <section className="surface">
              <h2>Bob · FYT buyer</h2>
              <div className="balance-row">
                <span>Fee claim</span>
                <strong>{format(bobFees0, " ETH")} / {format(bobFees1, " USDC")}</strong>
              </div>
              <div className="balance-row">
                <span>Yield PnL</span>
                <strong>{step === "redeemed" ? format(bobFees1 - fytSold, " USDC equiv") : "pending"}</strong>
              </div>
              <div className="token-strip">
                <span>FYT holder</span>
                <span>{stepIndex >= 2 && step !== "redeemed" ? "active" : "closed"}</span>
              </div>
            </section>
          </div>

          <section className="risk-band">
            <div>
              <strong>FYT risk</strong>
              <span>Buyer absorbs realized fee variance.</span>
            </div>
            <div>
              <strong>PT risk</strong>
              <span>Holder absorbs LP capital and IL exposure.</span>
            </div>
            <div>
              <strong>Settlement</strong>
              <span>Reactive callback, with permissionless fallback.</span>
            </div>
          </section>
        </section>
      </section>
    </main>
  );
}

function Metric({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="metric">
      <div>{icon}</div>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
