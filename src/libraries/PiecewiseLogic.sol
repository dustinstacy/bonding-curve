// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @notice PiecewiseLogic library originally from Zap Protocol found here:
///         https://github.com/zapproject/hardhat-eth/blob/1155market/contracts/lib/platform/PiecewiseLogic.sol
library PiecewiseLogic {
    function sumOfPowers(uint256 n, uint256 i) internal pure returns (uint256) {
        require(i <= 6 && i >= 0, "Error: Invalid Piecewise Logic");

        if (i == 0) return n;
        if (i == 1) return (n * (n + 1)) / 2;
        if (i == 2) return (n * (n + 1) * (2 * n + 1)) / 6;
        if (i == 3) return ((n * (n + 1)) / 2) ** 2;
        if (i == 4) return (n * (n + 1) * (2 * n + 1) * (3 * n * n + 3 * n - 1)) / 30;
        if (i == 5) return (n * (n + 1)) ** 2 * (2 * n ** 2 + 2 * n - 1);
        if (i == 6) return (n * (n + 1) * (2 * n + 1) * (3 * n ** 4 + 6 * n ** 3 - 3 * n + 1)) / 42;

        // impossible
        return 0;
    }

    function evaluateFunction(int256[] memory curve, uint256 a, uint256 b) internal pure returns (int256 sum) {
        uint256 i = 0;
        sum = 0;

        // Require to be within the curve limit
        require(a + b <= uint256(curve[curve.length - 1]), "Error: Function not in curve limit");

        // Loop invariant: i should always point to the start of a piecewise piece (the length)
        while (i < curve.length) {
            uint256 l = uint256(curve[i]);
            uint256 end = uint256(curve[i + l + 1]);

            // Index of the next piece's end
            uint256 nextIndex = i + l + 2;

            if (a > end) {
                // move on to the next piece
                i = nextIndex;
                continue;
            }

            sum += evaluatePiece(curve, i, a, (a + b > end) ? end - a : b);

            if (a + b <= end) {
                // Entire calculation is within this piece
                return sum;
            } else {
                b -= end - a + 1; // Remove the curve cost we've already bound from b
                a = end; // Move a up to the end
                i = nextIndex; // Move index up
            }
        }
    }

    function evaluatePiece(int256[] memory curve, uint256 index, uint256 a, uint256 b) internal pure returns (int256) {
        int256 sum = 0;
        uint256 len = uint256(curve[index]);
        uint256 base = index + 1;
        uint256 end = base + len; // index of last term

        // iterate between index+1 and the end of this piece
        for (uint256 i = base; i < end; i++) {
            sum += curve[i] * int256(sumOfPowers(a + b, i - base) - sumOfPowers(a - 1, i - base));
        }

        require(sum >= 0, "Error: Cost must be greater than zero");
        return sum;
    }
}
