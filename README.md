# Under-Constrained Circom Circuit, Demonstration Security Review

![tests](https://github.com/Musyg/circom-underconstrained-audit/actions/workflows/ci.yml/badge.svg)

A self-contained demonstration of a zero-knowledge circuit security review: a Circom circuit
that binds a signal with `<--` instead of `<==`, leaving a key relation out of the R1CS, the
Groth16 soundness break it allows (a proof accepted for a forged witness), and a `fixed`
branch where the same forged proof is rejected.

> This is a demonstration on intentionally vulnerable code. The circuit was written to
> showcase audit methodology end to end. It is not production code, not a real client
> engagement, and must never be deployed. The finding is a real vulnerability in this demo
> circuit, not an invented severity.

## Why this repo exists

Anyone can write "I audit ZK circuits" in a bio. This repo shows the work instead: a target,
a concrete finding, an executable proof, and a verified fix. If it isn't reproducible, it
isn't done.

## Repository layout

The review lives across two branches:

| Branch | Contents | What a green `npm test` means |
|--------|----------|-------------------------------|
| `master` | The under-constrained circuit and a PoC that forges a witness | a Groth16 proof is accepted for a public input the prover cannot actually satisfy |
| `fixed`  | The constrained circuit and the same forged witness | the forged proof is rejected by the verifier |

- `circuits/Square.circom`, the circuit under review
- `test/exploit.cjs`, the proof-of-concept (honest proof, then a forged witness)
- `scripts/setup.sh`, compile plus Groth16 setup (Powers of Tau, proving and verification keys)
- `Underconstrained_Circuit_Review.pdf`, the full written report

## Finding

| ID | Severity | Summary |
|----|----------|---------------------------------------------------------------|
| H-01 | High | Under-constrained signal. `Square.circom` binds `sq <-- root * root`, which assigns the witness but emits no constraint, so the R1CS only enforces `sq === n`. The private `root` appears in no constraint. A prover forges a witness with any `root` and `sq = n`, producing a Groth16 proof that the verifier accepts. The proof does not establish knowledge of a square root of `n`: soundness is broken. |

The circuit is meant to prove knowledge of a private `root` with `root^2 == n` for a public
`n`, the shape of a ZK authorization gate. Because `root` is unconstrained, the gate proves
nothing about it.

PoC numbers: with public `n = 9`, an honest prover uses `root = 3` and the proof verifies. The
PoC then forges a witness with `root = 7` (and `7^2 = 49`, not `9`), leaving `sq = 9`. On
`master` the forged proof verifies, so a caller proves knowledge of a square root of 9 without
knowing one. On `fixed` the same forged proof is rejected.

## Reproduce it

Requires Node.js 20+, the [circom](https://docs.circom.io) 2.x compiler on `PATH`, and
[snarkjs](https://github.com/iden3/snarkjs) (installed as a dependency).

```bash
git clone https://github.com/Musyg/circom-underconstrained-audit.git
cd circom-underconstrained-audit
npm install
npm run setup     # compile the circuit and run the Groth16 setup

# master: the forged proof is accepted (soundness broken)
npm test

# fixed: the same forged proof is rejected
git checkout fixed
npm run setup
npm test
```

## The fix

Bind `sq` with `<==`, which assigns the witness and emits the constraint `sq == root * root`:

```circom
sq <== root * root;
sq === n;
```

Now the R1CS enforces `root * root == n`, so a witness with a wrong `root` no longer satisfies
the circuit and its proof fails verification. The rule is mechanical: a value a circuit relies
on must be bound with `<==` or pinned by an explicit `===` constraint. `<--` alone assigns a
witness without proving anything about it.

## How severity is rated

High: a soundness break. A prover can produce a verifying proof for a statement they cannot
actually satisfy. In a circuit used as an authorization or state-transition gate, that is a
full bypass of the property the proof was supposed to guarantee.
