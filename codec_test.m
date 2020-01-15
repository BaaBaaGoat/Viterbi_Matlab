function outrate = codec_test(errrate)
%% 维特比解码（整体回溯）
a=poly2trellis(7,[171 133]);%多项式
%% 自行实现编码
din = [randi([0 1],1000,1);zeros(32,1)];
stat = NaN(numel(din),1);
code = NaN(numel(din),1);
for i=1:numel(din)
    if(i==1)
        code(i) = a.outputs(1,din(i)+1);
        stat(i) = a.nextStates(1,din(i)+1)+1;%初始状态
    else
        code(i) = a.outputs(stat(i-1),din(i)+1);
        stat(i) = a.nextStates(stat(i-1),din(i)+1)+1;
    end
end
%% 加入误码
err = (rand(length(code),2) < errrate) * [2;1];
code = bitxor(code,err);
%% 自行实现解码（整体回溯）
decode_buff = cell(64,1033);%回溯缓存
for i=1:64,decode_buff{i,1} = [];end
decode_errcnt = NaN(64,1033);% 到此状态需要的误码数量
decode_errcnt(:,1) = inf(64,1);decode_errcnt(1,1)=0;%初始分布
for i=2:1033%处理序列的第几个成员
    for j=1:64%正在被处理的状态
        % 1. 找到哪两个状态可以转移到这个状态
        source = find(any(a.nextStates == j-1,2),2);
        % 2. 查出这两个状态转换过来对应的编码输出
        correct = a.outputs(source,1+floor((j-1)/32));%两列对应0/1的输入，也对应新状态的最高位。
        %3. 计算这两个状态转换过来的概率（需要的误码数量）
        conv_dist = zeros(2,1);
        for k=1:2
            conv_dist(k) = CalcDist(correct(k),code(i-1)) + decode_errcnt(source(k),i-1);
        end
        
        % 4. 判断来源于哪个的概率更大
        [errcnt,choice] = min(conv_dist);
        choice = source(choice);
        % 5. 存储找到的路径和概率
        decode_errcnt(j,i) = errcnt;
        decode_buff{j,i} = [decode_buff{choice,i-1},choice];
    end
end
decode = [floor((decode_buff{1,end}(2:end)-1)/32)';0];
outrate = sum(din~=decode)/numel(decode);
end
function y=CalcDist(x1,x2)
    temp = bitxor(x1,x2);
    switch(temp)
        case 0
            y=0;
        case 1
            y=1;
        case 2
            y=1;
        case 3
            y=3;
    end
end