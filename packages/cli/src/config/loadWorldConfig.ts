import { z, ZodError } from "zod";
import { fromZodErrorCustom } from "../utils/errors.js";
import { BaseRoute, ObjectName } from "./commonSchemas.js";
import { loadConfig } from "./loadConfig.js";
import { validateEthereumAddressOrSystemName } from "./validation.js";

// Object names have to start with a capital letter and only contain letters, numbers and underscores
const SystemName = ObjectName;

// Base routes are ordinary routes with an empty string as a valid value
const SystemRoute = z.object({ route: BaseRoute.default("") });

// Each element in the SystemAccessList must be a valid Ethereum address or a valid system name
const SystemAccessList = z.array(z.string()).superRefine((arr, ctx) => {
  arr.forEach((element) => validateEthereumAddressOrSystemName(element, ctx));
});

// System access is a union type of either open access or access restricted to a list of addresses or systems
const SystemAccess = z
  .discriminatedUnion("openAccess", [
    z.object({
      openAccess: z.literal(true),
    }),
    z.object({
      openAccess: z.literal(false),
      accessList: SystemAccessList,
    }),
  ])
  .default({ openAccess: true });

// The system config is a combination of a route config and access config
const System = z.intersection(SystemRoute, SystemAccess);

export const WorldConfig = z.object({
  baseRoute: BaseRoute.default(""),
  worldPath: z.string().optional(),
  overrideSystems: z.record(SystemName, System).default({}),
  excludeSystems: z.array(SystemName).default([]),
});

// zod doesn't preserve doc comments
export type SystemConfig =
  | {
      /** The system will be deployed at `baseRoute + route` */
      route: string;
    } & (
      | {
          /** If openAccess is true, any address can call the system */
          openAccess: true;
        }
      | {
          /** If openAccess is false, only the addresses or systems in `access` can call the system */
          openAccess: false;
          /** An array of addresses or system names that can access the system */
          accessList: string[];
        }
    );

// zod doesn't preserve doc comments
export interface WorldUserConfig {
  /** The base route to register tables and systems at. Defaults to the root route (empty string) */
  baseRoute?: string;
  /** The path to the World contract to deploy. If no world path is provided, a vanilla World is deployed */
  worldPath?: string;
  /**
   * Contracts named *System files will be deployed by default
   * as public systems at `baseRoute/ContractName`, unless overridden
   *
   * The key is the system name (capitalized).
   * The value is a SystemConfig object.
   */
  overrideSystems?: Record<string, SystemConfig>;
  /** Systems to exclude from automatic deployment */
  excludeSystems?: string[];
}

// Same as WorldUserConfig, but without optional fields (because of default values)
export type WorldConfig = z.output<typeof WorldConfig>;

export async function loadWorldConfig(configPath?: string) {
  const config = await loadConfig(configPath);

  try {
    return WorldConfig.parse(config);
  } catch (error) {
    if (error instanceof ZodError) {
      throw fromZodErrorCustom(error, "WorldConfig Validation Error");
    } else {
      throw error;
    }
  }
}
