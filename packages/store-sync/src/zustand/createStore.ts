import { SchemaToPrimitives, Table, Tables } from "@latticexyz/store";
import { StoreApi, UseBoundStore, create } from "zustand";
import { RawRecord, TableRecord } from "./common";
import { Hex } from "viem";
import { encodeKey } from "@latticexyz/protocol-parser";
import { flattenSchema } from "../flattenSchema";
import { getId } from "./getId";
import { SyncStep } from "../SyncStep";

type TableRecords<table extends Table> = {
  readonly [id: string]: TableRecord<table>;
};

// TODO: split this into distinct stores and combine (https://docs.pmnd.rs/zustand/guides/typescript#slices-pattern)?

export type ZustandState<tables extends Tables> = {
  readonly syncProgress: {
    readonly step: SyncStep;
    readonly message: string;
    readonly percentage: number;
    readonly latestBlockNumber: bigint;
    readonly lastBlockNumberProcessed: bigint;
  };
  /** Tables derived from table registration store events */
  readonly tables: {
    readonly [tableId: Hex]: Table;
  };
  /** Raw records (bytes) derived from store events */
  readonly rawRecords: {
    readonly [id: string]: RawRecord;
  };
  /** Decoded table records derived from raw records */
  readonly records: {
    readonly [id: string]: TableRecord<tables[keyof tables]>;
  };
  readonly getRecords: <table extends Table>(table: table) => TableRecords<table>;
  readonly getRecord: <table extends Table>(
    table: table,
    key: SchemaToPrimitives<table["keySchema"]>,
  ) => TableRecord<table> | undefined;
  readonly getValue: <table extends Table>(
    table: table,
    key: SchemaToPrimitives<table["keySchema"]>,
  ) => TableRecord<table>["value"] | undefined;
};

export type ZustandStore<tables extends Tables> = UseBoundStore<StoreApi<ZustandState<tables>>>;

export type CreateStoreOptions<tables extends Tables> = {
  tables: tables;
};

export function createStore<tables extends Tables>(opts: CreateStoreOptions<tables>): ZustandStore<tables> {
  return create<ZustandState<tables>>((set, get) => ({
    syncProgress: {
      step: SyncStep.INITIALIZE,
      message: "Connecting",
      percentage: 0,
      latestBlockNumber: 0n,
      lastBlockNumberProcessed: 0n,
    },
    tables: Object.fromEntries(Object.entries(opts.tables).map(([, table]) => [table.tableId, table])),
    rawRecords: {},
    records: {},
    getRecords: <table extends Table>(table: table): TableRecords<table> => {
      const records = get().records;
      return Object.fromEntries(
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        Object.entries(records).filter(([id, record]) => record.table.tableId === table.tableId),
      ) as unknown as TableRecords<table>;
    },
    getRecord: <table extends Table>(
      table: table,
      key: SchemaToPrimitives<table["keySchema"]>,
    ): TableRecord<table> | undefined => {
      const keyTuple = encodeKey(flattenSchema(table.keySchema), key);
      const id = getId({ tableId: table.tableId, keyTuple });
      return get().records[id] as unknown as TableRecord<table> | undefined;
    },
    getValue: <table extends Table>(
      table: table,
      key: SchemaToPrimitives<table["keySchema"]>,
    ): TableRecord<table>["value"] | undefined => {
      return get().getRecord(table, key)?.value;
    },
  }));
}
