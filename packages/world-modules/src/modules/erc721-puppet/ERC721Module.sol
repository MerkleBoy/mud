// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Module } from "@latticexyz/world/src/Module.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { InstalledModules } from "@latticexyz/world/src/codegen/tables/InstalledModules.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";

import { Puppet } from "../puppet/Puppet.sol";
import { createPuppet } from "../puppet/createPuppet.sol";
import { MODULE_NAME as PUPPET_MODULE_NAME } from "../puppet/constants.sol";
import { Balances } from "../tokens/tables/Balances.sol";

import { MODULE_NAME, MODULE_NAMESPACE, MODULE_NAMESPACE_ID, ERC721_REGISTRY_TABLE_ID } from "./constants.sol";
import { _erc721SystemId, _balancesTableId, _metadataTableId, _tokenUriTableId, _operatorApprovalTableId, _ownersTableId, _tokenApprovalTableId } from "./utils.sol";
import { ERC721System } from "./ERC721System.sol";

import { OperatorApproval } from "../tokens/tables/OperatorApproval.sol";
import { ERC721Owners } from "./tables/ERC721Owners.sol";
import { ERC721TokenApproval } from "./tables/ERC721TokenApproval.sol";
import { TokenURI } from "../tokens/tables/TokenURI.sol";
import { ERC721Registry } from "./tables/ERC721Registry.sol";
import { ERC721Metadata, ERC721MetadataData } from "./tables/ERC721Metadata.sol";

contract ERC721Module is Module {
  error ERC721Module_InvalidNamespace(bytes14 namespace);

  address immutable registrationLibrary = address(new ERC721ModuleRegistrationLibrary());

  function getName() public pure override returns (bytes16) {
    return MODULE_NAME;
  }

  function _requireDependencies() internal view {
    // Require PuppetModule to be installed
    if (!isInstalled(PUPPET_MODULE_NAME, new bytes(0))) {
      revert Module_MissingDependency(string(bytes.concat(PUPPET_MODULE_NAME)));
    }
  }

  function install(bytes memory args) public {
    // Require the module to not be installed with these args yet
    requireNotInstalled(MODULE_NAME, args);

    // Extract args
    (bytes14 namespace, ERC721MetadataData memory metadata) = abi.decode(args, (bytes14, ERC721MetadataData));

    // Require the namespace to not be the module's namespace
    if (namespace == MODULE_NAMESPACE) {
      revert ERC721Module_InvalidNamespace(namespace);
    }

    // Require dependencies
    _requireDependencies();

    // Register the ERC721 tables and system
    IBaseWorld world = IBaseWorld(_world());
    (bool success, bytes memory returnData) = registrationLibrary.delegatecall(
      abi.encodeCall(ERC721ModuleRegistrationLibrary.register, (world, namespace))
    );
    if (!success) revertWithBytes(returnData);

    // Initialize the Metadata
    ERC721Metadata.set(_metadataTableId(namespace), metadata);

    // Deploy and register the ERC721 puppet.
    ResourceId erc721SystemId = _erc721SystemId(namespace);
    address puppet = createPuppet(world, erc721SystemId);

    // Transfer ownership of the namespace to the caller
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    world.transferOwnership(namespaceId, _msgSender());

    // Register the ERC721 in the ERC20Registry
    if (!ResourceIds.getExists(ERC721_REGISTRY_TABLE_ID)) {
      world.registerNamespace(MODULE_NAMESPACE_ID);
      ERC721Registry.register(ERC721_REGISTRY_TABLE_ID);
    }
    ERC721Registry.set(ERC721_REGISTRY_TABLE_ID, namespaceId, puppet);
  }

  function installRoot(bytes memory) public pure {
    revert Module_RootInstallNotSupported();
  }
}

contract ERC721ModuleRegistrationLibrary {
  /**
   * Register systems and tables for a new ERC721 token in a given namespace
   */
  function register(IBaseWorld world, bytes14 namespace) public {
    // Register the namespace if it doesn't exist yet
    ResourceId tokenNamespace = WorldResourceIdLib.encodeNamespace(namespace);
    if (!ResourceIds.getExists(tokenNamespace)) {
      world.registerNamespace(tokenNamespace);
    }

    // Register the tables
    OperatorApproval.register(_operatorApprovalTableId(namespace));
    ERC721Owners.register(_ownersTableId(namespace));
    ERC721TokenApproval.register(_tokenApprovalTableId(namespace));
    TokenURI.register(_tokenUriTableId(namespace));
    Balances.register(_balancesTableId(namespace));
    ERC721Metadata.register(_metadataTableId(namespace));

    // Register a new ERC20System
    world.registerSystem(_erc721SystemId(namespace), new ERC721System(), true);
  }
}
