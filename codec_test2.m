function outrate = codec_test2(errrate,backtrack,N)
% ά�رȽ��루������ݣ�
%N=�������Ϣ����
%backtrack=���ݳ��ȣ����50(��Ϊ��double��װ��
    a=poly2trellis(7,[171 133]);
    backtrack_window = bitshift(1,backtrack)-1;
    %% ����ʵ�ֱ���
    din = [randi([0 1],N,1);zeros(backtrack,1)];
    stat = NaN(numel(din),1);
    code = NaN(numel(din),1);
    for i=1:numel(din)
        if(i==1)
            code(i) = a.outputs(1,din(i)+1);
            stat(i) = a.nextStates(1,din(i)+1)+1;%��ʼ״̬
        else
            code(i) = a.outputs(stat(i-1),din(i)+1);
            stat(i) = a.nextStates(stat(i-1),din(i)+1)+1;
        end
    end

    %% ��������
    err = (rand(length(code),2) < errrate) * [2;1];
    code = bitxor(code,err);

    %% ����ʵ�ֽ��루�������ݣ�
    decode_buff = zeros(64,1);%���ݻ���
    decode_errcnt = inf(64,1);decode_errcnt(1,1)=0;%��ʼ�ֲ�
    decode_buff_old = decode_buff;%���ݻ���
    decode_errcnt_old = decode_errcnt;%��ʼ�ֲ�
    decode_Output =  zeros(64,1);
    
    best_Output =  zeros(N+1+backtrack,1);
    errcnt_Output =  zeros(N+1+backtrack,1);
    for i=2:(N+1+backtrack)%�������еĵڼ�����Ա
        for j=1:64%���ڱ������״̬
            % 1. �ҵ�������״̬����ת�Ƶ����״̬
            source = find(any(a.nextStates == j-1,2),2);
            % 2. ���������״̬ת��������Ӧ�ı������
            correct = a.outputs(source,1+floor((j-1)/32));%���ж�Ӧ0/1�����룬Ҳ��Ӧ��״̬�����λ��
            %3. ����������״̬ת�������ĸ���
            conv_dist = CalcDist(correct,code(i-1)) + decode_errcnt_old(source);
            % 4. �ж���Դ���ĸ��ĸ��ʸ���
            [errcnt,choice] = min(conv_dist);
            choice = source(choice);
            % 5. �洢�ҵ���·���͸���
            decode_errcnt(j) = errcnt;
            decode_Output(j) = bitget(decode_buff_old(j),backtrack);
            decode_buff(j) = bitand(2*decode_buff_old(choice)+floor((j-1)/32),backtrack_window);
        end
        decode_errcnt_old = decode_errcnt;
        decode_buff_old = decode_buff;
        
        % 6. �жϵ�ǰ���п��ܵ�״̬
        [best_stat_errcnt,best_stat] = min(decode_errcnt);
        % 7. ������п��ܵ�״̬��Ӧ�Ľ�����
        best_Output(i) = decode_Output(best_stat);
        errcnt_Output(i) = best_stat_errcnt;
    end
    %%����������
    Output=best_Output((backtrack+2):end);
    din = din(1:end-backtrack);
    outrate = sum(Output~=din)/numel(din);
end


function y=CalcDist(x1,x2)
%���㺺������,����Ϊ����һ�����ʸ���������ֵΪ0~3����
    temp = bitxor(x1,x2);
    y=bitget(temp,1)+bitget(temp,2);%д��sum(bitget(temp,[1 2])�����ܽ���ʸ������
end
