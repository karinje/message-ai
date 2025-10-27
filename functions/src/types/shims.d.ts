// Lightweight shims to avoid heavy type analysis during build
declare module "@langchain/langgraph" {
  const anyExport: any;
  export = anyExport;
}

declare module "@langchain/openai" {
  export class ChatOpenAI {
    constructor(opts?: any);
    bind(opts?: any): this;
    invoke(input: any): Promise<any>;
  }
}

declare module "@langchain/core/tools" {
  export function tool(fn: (...args: any[]) => any, cfg: any): any;
}

declare module "zod" {
  const z: any;
  export default z;
}

