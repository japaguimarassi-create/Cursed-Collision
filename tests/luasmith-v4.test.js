import test from "node:test";
import assert from "node:assert/strict";
import {OperationPolicy,ReferenceEngine,RepositoryIndex,parseJson,allowed} from "../luasmith-v4.js";
test("ESM startup",()=>assert.equal(typeof RepositoryIndex,"function"));
test("operation policy rejects unsafe changes",()=>{
  assert.equal(allowed("src/A.lua"),true);
  assert.equal(allowed("../../etc/passwd"),false);
  assert.throws(()=>OperationPolicy.validate([{action:"delete",path:"src/a.lua",content:"x"}]));
  assert.throws(()=>OperationPolicy.validate([{action:"update_file",path:"src/a.lua",content:"loadstring('x')"}]));
  assert.throws(()=>OperationPolicy.validate([{action:"update_file",path:"src/a.lua",content:"ROBLOX_API_KEY=secret"}]));
});
test("repair parser accepts JSON",()=>assert.equal(parseJson("{\\"status\\":\\"ok\\",\\"operations\\":[]}").status,"ok"));
test("reference and repository indexes work",()=>{
  const refs=new ReferenceEngine("/tmp/luasmith-v4-refs.json").load();
  assert.ok(refs.search("Roblox analytics").length>0);
  assert.ok(refs.records.every(x=>x.url.startsWith("http")));
  assert.ok(Array.isArray(new RepositoryIndex(process.cwd()).build().files));
});