// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { ISystemHook } from "./../../ISystemHook.sol";
import { System } from "./../../System.sol";

/**
 * @title IWorldRegistrationSystem
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IWorldRegistrationSystem {
  function registerNamespace(ResourceId namespaceId) external;

  function registerSystemHook(ResourceId systemId, ISystemHook hookAddress, uint8 enabledHooksBitmap) external;

  function unregisterSystemHook(ResourceId systemId, ISystemHook hookAddress) external;

  function registerSystem(ResourceId systemId, System system, bool publicAccess) external;

  function registerFunctionSelector(
    ResourceId systemId,
    string memory systemFunctionSignature
  ) external returns (bytes4 worldFunctionSelector);

  function registerRootFunctionSelector(
    ResourceId systemId,
    string memory worldFunctionSignature,
    bytes4 systemFunctionSelector
  ) external returns (bytes4 worldFunctionSelector);

  function registerDelegation(address delegatee, ResourceId delegationControlId, bytes memory initCallData) external;

  function unregisterDelegation(address delegatee) external;

  function registerNamespaceDelegation(
    ResourceId namespaceId,
    ResourceId delegationControlId,
    bytes memory initCallData
  ) external;

  function unregisterNamespaceDelegation(ResourceId namespaceId) external;
}
