// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title ITasksSystem
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITasksSystem {
  function addTask(string memory description) external returns (bytes32 key);

  function completeTask(bytes32 key) external;

  function resetTask(bytes32 key) external;

  function deleteTask(bytes32 key) external;
}
