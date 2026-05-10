import { base, baseSepolia } from 'viem/chains';
import { env } from '$env/dynamic/public';

export const chain = env.PUBLIC_CHAIN === 'base' ? base : baseSepolia;

export const BRICK_CONTRACT = (env.PUBLIC_BRICK_CONTRACT ?? '0x0') as `0x${string}`;
export const WALL_TOKEN = (env.PUBLIC_WALL_TOKEN ?? '0x0') as `0x${string}`;
export const WALL_HOOK = (env.PUBLIC_WALL_HOOK ?? '0x0') as `0x${string}`;

export const RPC_URL = env.PUBLIC_BASE_RPC ?? 'https://sepolia.base.org';
export const PINATA_GATEWAY = env.PUBLIC_PINATA_GATEWAY ?? 'https://gateway.pinata.cloud/ipfs/';
