-- 获取HTTP的Header值
function get_header(key)
    local headers = ngx.req.get_headers();
    for k, v in pairs(headers) do
      if(k == key) then
          return v
      end
    end
    -- return "";
end
local shop_id = get_header("shopid");