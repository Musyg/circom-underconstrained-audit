pragma circom 2.1.6;

// Square (vulnerable)
//
// Proves knowledge of a private `root` such that root^2 == n, where `n` is public.
// Intended use: a gate that only someone knowing a square root of `n` can pass.
//
// BUG: `sq` is bound with `<--` (witness assignment only), so the relation
// `sq == root * root` is NEVER added to the R1CS. The only constraint emitted is
// `sq === n`. The signal `root` therefore appears in no constraint at all: a prover
// can pick any `root` and still satisfy the circuit by providing a witness with
// `sq = n`. Soundness is broken: the proof does not establish knowledge of a root.

template Square() {
    signal input root;   // private
    signal input n;      // public
    signal sq;
    sq <-- root * root;  // BUG: should be <== to also constrain sq == root*root
    sq === n;
}

component main {public [n]} = Square();
