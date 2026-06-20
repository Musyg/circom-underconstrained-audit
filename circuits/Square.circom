pragma circom 2.1.6;

// Square (remediated)
//
// `sq` is now bound with `<==`, which both assigns the witness and emits the constraint
// `sq == root * root`. Together with `sq === n`, the circuit enforces `root * root == n`,
// so the proof genuinely establishes knowledge of a square root of `n`. A witness with a
// wrong `root` no longer satisfies the constraints, and its proof is rejected.

template Square() {
    signal input root;   // private
    signal input n;      // public
    signal sq;
    sq <== root * root;  // assigns AND constrains sq == root * root
    sq === n;
}

component main {public [n]} = Square();
