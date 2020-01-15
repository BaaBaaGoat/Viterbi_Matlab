function outrate = codec_test(errrate)
%% ά�رȽ��루������ݣ�
a=poly2trellis(7,[171 133]);%����ʽ
%% ����ʵ�ֱ���
din = [randi([0 1],1000,1);zeros(32,1)];
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
%% ����ʵ�ֽ��루������ݣ�
decode_buff = cell(64,1033);%���ݻ���
for i=1:64,decode_buff{i,1} = [];end
decode_errcnt = NaN(64,1033);% ����״̬��Ҫ����������
decode_errcnt(:,1) = inf(64,1);decode_errcnt(1,1)=0;%��ʼ�ֲ�
for i=2:1033%�������еĵڼ�����Ա
    for j=1:64%���ڱ������״̬
        % 1. �ҵ�������״̬����ת�Ƶ����״̬
        source = find(any(a.nextStates == j-1,2),2);
        % 2. ���������״̬ת��������Ӧ�ı������
        correct = a.outputs(source,1+floor((j-1)/32));%���ж�Ӧ0/1�����룬Ҳ��Ӧ��״̬�����λ��
        %3. ����������״̬ת�������ĸ��ʣ���Ҫ������������
        conv_dist = zeros(2,1);
        for k=1:2
            conv_dist(k) = CalcDist(correct(k),code(i-1)) + decode_errcnt(source(k),i-1);
        end
        
        % 4. �ж���Դ���ĸ��ĸ��ʸ���
        [errcnt,choice] = min(conv_dist);
        choice = source(choice);
        % 5. �洢�ҵ���·���͸���
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