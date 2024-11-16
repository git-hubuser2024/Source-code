function str = helperPrintLaurent(poly)
cfLength = length(poly.Coefficients);
dePow = poly.MaxOrder;
if poly.Coefficients(1) ~= 0
    str = helperCheckCfPow(poly.Coefficients(1),dePow);
    if sign(poly.Coefficients(1))==-1
        str = "- "+str;
    end
else
    str = '';
end
for k=2:cfLength
    dePow = dePow-1;
    tmpCf = poly.Coefficients(k);
    tmp = helperCheckCfPow(tmpCf,dePow);
    switch sign(tmpCf)
        case 1
            str = str+" + "+tmp;
        case -1
            str = str+" - "+tmp;
    end
end
end

function tOut = helperCheckCfPow(cf,zpow)

switch zpow
    case 0
        tOut = abs(cf);
    case 1
        if abs(cf) == 1
            tOut = "z";
        else
            tOut = abs(cf)+"*z";
        end
    otherwise
        if abs(cf) == 1
            tOut = sprintf("z^(%d)",zpow);
        else
            tOut = abs(cf)+sprintf("*z^(%d)",zpow);
        end
end
end
