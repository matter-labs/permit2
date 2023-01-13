// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAllowanceTransferERC1155} from "../interfaces/IAllowanceTransferERC1155.sol";
import {ISignatureTransferERC1155} from "../interfaces/ISignatureTransferERC1155.sol";

library PermitHashERC1155 {
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256("PermitDetails(address token,uint256 tokenId,uint160 amount,uint48 expiration,uint48 nonce)");

    bytes32 public constant _PERMIT_SINGLE_TYPEHASH = keccak256(
        "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint256 tokenId,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    bytes32 public constant _PERMIT_BATCH_TYPEHASH = keccak256(
        "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint256 tokenId,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    bytes32 public constant _PERMIT_ALL_TYPEHASH =
        keccak256("PermitAll(address token,address spender,uint48 expiration,uint48 nonce,uint256 sigDeadline)");

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    string public constant _TOKEN_PERMISSIONS_TYPESTRING = "TokenPermissions(address token,uint256 amount)";

    string public constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    string public constant _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB =
        "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,";

    function hash(IAllowanceTransferERC1155.PermitSingle memory permitSingle) internal pure returns (bytes32) {
        bytes32 permitHash = _hashPermitDetails(permitSingle.details);
        return
            keccak256(abi.encode(_PERMIT_SINGLE_TYPEHASH, permitHash, permitSingle.spender, permitSingle.sigDeadline));
    }

    function hash(IAllowanceTransferERC1155.PermitBatch memory permitBatch) internal pure returns (bytes32) {
        uint256 numPermits = permitBatch.details.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitDetails(permitBatch.details[i]);
        }
        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                permitBatch.spender,
                permitBatch.sigDeadline
            )
        );
    }

    function hash(IAllowanceTransferERC1155.PermitAll memory permitAll) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _PERMIT_ALL_TYPEHASH,
                permitAll.token,
                permitAll.spender,
                permitAll.expiration,
                permitAll.nonce,
                permitAll.sigDeadline
            )
        );
    }

    function hash(ISignatureTransferERC1155.PermitTransferFrom memory permit) internal view returns (bytes32) {
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(
            abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline)
        );
    }

    function hash(ISignatureTransferERC1155.PermitBatchTransferFrom memory permit) internal view returns (bytes32) {
        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                msg.sender,
                permit.nonce,
                permit.deadline
            )
        );
    }

    function hashWithWitness(
        ISignatureTransferERC1155.PermitTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeString));

        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(abi.encode(typeHash, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline, witness));
    }

    function hashWithWitness(
        ISignatureTransferERC1155.PermitBatchTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash =
            keccak256(abi.encodePacked(_PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, witnessTypeString));

        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                typeHash,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                msg.sender,
                permit.nonce,
                permit.deadline,
                witness
            )
        );
    }

    function _hashPermitDetails(IAllowanceTransferERC1155.PermitDetails memory details)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, details));
    }

    function _hashTokenPermissions(ISignatureTransferERC1155.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }
}
