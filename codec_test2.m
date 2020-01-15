function outrate = codec_test2(errrate,backtrack,N)
% 维特比解码（整体回溯）
%N=仿真的消息长度
%backtrack=回溯长度，最大50(因为用double来装）
    a=poly2trellis(7,[171 133]);
    backtrack_window = bitshift(1,backtrack)-1;
    %% 自行实现编码
    din = [randi([0 1],N,1);zeros(backtrack,1)];
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

    %% 自行实现解码（定长回溯）
    decode_buff = zeros(64,1);%回溯缓存
    decode_errcnt = inf(64,1);decode_errcnt(1,1)=0;%初始分布
    decode_buff_old = decode_buff;%回溯缓存
    decode_errcnt_old = decode_errcnt;%初始分布
    decode_Output =  zeros(64,1);
    
    best_Output =  zeros(N+1+backtrack,1);
    errcnt_Output =  zeros(N+1+backtrack,1);
    for i=2:(N+1+backtrack)%处理序列的第几个成员
        for j=1:64%正在被处理的状态
            % 1. 找到哪两个状态可以转移到这个状态
            source = find(any(a.nextStates == j-1,2),2);
            % 2. 查出这两个状态转换过来对应的编码输出
            correct = a.outputs(source,1+floor((j-1)/32));%两列对应0/1的输入，也对应新状态的最高位。
            %3. 计算这两个状态转换过来的概率
            conv_dist = CalcDist(correct,code(i-1)) + decode_errcnt_old(source);
            % 4. 判断来源于哪个的概率更大
            [errcnt,choice] = min(conv_dist);
            choice = source(choice);
            % 5. 存储找到的路径和概率
            decode_errcnt(j) = errcnt;
            decode_Output(j) = bitget(decode_buff_old(j),backtrack);
            decode_buff(j) = bitand(2*decode_buff_old(choice)+floor((j-1)/32),backtrack_window);
        end
        decode_errcnt_old = decode_errcnt;
        decode_buff_old = decode_buff;
        
        % 6. 判断当前最有可能的状态
        [best_stat_errcnt,best_stat] = min(decode_errcnt);
        % 7. 输出最有可能的状态对应的解码结果
        best_Output(i) = decode_Output(best_stat);
        errcnt_Output(i) = best_stat_errcnt;
    end
    %%计算误码率
    Output=best_Output((backtrack+2):end);
    din = din(1:end-backtrack);
    outrate = sum(Output~=din)/numel(din);
end


function y=CalcDist(x1,x2)
%计算汉明距离,输入为两个一样大的矢量，里面的值为0~3整数
    temp = bitxor(x1,x2);
    y=bitget(temp,1)+bitget(temp,2);%写成sum(bitget(temp,[1 2])）不能接收矢量输入
end
