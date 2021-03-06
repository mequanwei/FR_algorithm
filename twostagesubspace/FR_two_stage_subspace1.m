function [ label_recorder distance_recorder] = FR_two_stage_subspace1(A,class_num,sample_num)
%Method 1:
%peaked M cloest subspace for building farthest subspace
M=5;
test_num=1;        %experiment times
train_num=7;       %samples used for trainning in each class
test_sample_num=14;%samples used in tests in each class
label_recorder=zeros(3,test_sample_num*class_num);
distance_recorder=zeros(3,test_sample_num*class_num);
[n_A, m_A]=size(A);
oneshot_average_correct_rate1=zeros(1,test_num);
oneshot_average_correct_rate2=zeros(1,test_num);
oneshot_average_correct_rate3=zeros(1,test_num);
for test=1:test_num
    disp(['test number=  ',num2str(test)])
    %to set matrix train_A train samples
    % and matrix test_A test samples
    tmp_index_test=zeros(1,test_sample_num*class_num);
    tmp_index_train=zeros(1,train_num*class_num);
    
    %method 1 randomly pick test samples
%     for tmp_i=1:class_num
%         tmp=randperm(sample_num);
%         tmp_index_test(1+(tmp_i-1)*test_sample_num:tmp_i*test_sample_num)=tmp(1:test_sample_num)+(tmp_i-1)*sample_num;
%         tmp_index_train(1+(tmp_i-1)*train_num:tmp_i*train_num)=tmp(test_sample_num+1:sample_num)+(tmp_i-1)*sample_num;
%     end
 %   method 2 pick the test sample manually
        train_sample_index= [1,7,8,9,36,37,38];%[1,3,5,7,9,11,13,15];%1:5;
        train_num=size(train_sample_index,2);%samples used for trainning in each class
        test_sample_index=[18,21:26,47,50:55];%[2,4,6,8,10,12,14];%6:10;
        test_sample_num=size(test_sample_index,2);%samples used in tests in each class
    for tmp_i=1:class_num
        tmp_index_test(1+(tmp_i-1)*test_sample_num:tmp_i*test_sample_num)= test_sample_index+(tmp_i-1)*sample_num;
        tmp_index_train(1+(tmp_i-1)*train_num:tmp_i*train_num)=train_sample_index+(tmp_i-1)*sample_num;
    end
    %method 3 "leave-one-out"
    %      tmp_index_test=test:sample_num:class_num*sample_num;
    %    tmp_index_train=setxor([1:class_num*sample_num], tmp_index_test) ;
    %====================================
    train_A=A( tmp_index_train,:) ;
    test_A=A( tmp_index_test,:) ;
    counter1=0; counter2=0; counter3=0;
    %===========================
    %the linear subspaces spanned by the trainning samples each without samples
    %from one class
    project_invMatrix1=cell(1,class_num);
    tmp_cell_x=cell(1,class_num);
    X= train_A(:,1:size(A,2)-1)';
    for i=1:class_num
        x=X(:,1+(i-1)*train_num:i*train_num);
        project_invMatrix1{i}=inv(x'*x);%x*((x'*x)^-1)*x';
        tmp_cell_x{i}=x;
    end
    num_of_test_test_sample=size(test_A,1);
    
    %query image testing
    for test_sample_No=1:num_of_test_test_sample
        
        test_sample=test_A(test_sample_No,1:(m_A-1))';
        d1_vector=zeros(1,class_num);
        d2_vector=zeros(1,M);
        d3_vector=zeros(1,M);
        
        for j=1:class_num
            project_space1=tmp_cell_x{j}*project_invMatrix1{j}*tmp_cell_x{j}';
            d1_vector(j)=norm(test_sample- project_space1*test_sample);
        end
        [d1_sorted tmp_index]=sortrows( d1_vector');
        d1=tmp_index(1);
        
        %+++++++Farthest subspace++++++++++++
        neighbor_class_index=tmp_index(1:M)';
        leave_one_class_out_subspace=zeros(train_num*(M-1),m_A-1);
        for ii=2:M
            leave_one_class_out_subspace((ii-2)*train_num+1:(ii-1)*train_num,:)=tmp_cell_x{neighbor_class_index(ii)}';
        end
        
        for dis_d2=1:M
            project_matrix2=leave_one_class_out_subspace'*inv(leave_one_class_out_subspace*leave_one_class_out_subspace')*leave_one_class_out_subspace;
            d2_vector(dis_d2)=norm(test_sample-project_matrix2*test_sample);
             leave_one_class_out_subspace((dis_d2-1)*train_num+1:dis_d2*train_num,:)=tmp_cell_x{neighbor_class_index(dis_d2)}';
        end
        
        %+++++++++++++++++++++++++++++++++++++
        
        
        tmp_max_d2=max(d2_vector);
        d2=tmp_index(find(d2_vector==tmp_max_d2));
        d3_vector=d1_sorted(1:M)'./d2_vector;
        tmp_min_d3=min(d3_vector);
        d3=tmp_index(find(d3_vector==tmp_min_d3));
        
        counter1=counter1+(d1==test_A(test_sample_No,m_A));
        counter2=counter2+(d2==test_A(test_sample_No,m_A));
        counter3=counter3+(d3==test_A(test_sample_No,m_A));
        label_recorder(:,test_sample_No)=[d1,d2,d3];
        distance_recorder(:,test_sample_No)=[d1_sorted(1),tmp_max_d2,tmp_min_d3];
    end
    
    
    oneshot_average_correct_rate1(test)=counter1/(test_sample_num*class_num);
    oneshot_average_correct_rate2(test)=counter2/(test_sample_num*class_num);
    oneshot_average_correct_rate3(test)=counter3/(test_sample_num*class_num);
    
end
average_correct_rate1=mean(oneshot_average_correct_rate1);average_correct_rate1_std=std(oneshot_average_correct_rate1);
disp(['correct rate for method 1:  ', num2str(average_correct_rate1),'  std=',num2str(average_correct_rate1_std) ])
average_correct_rate2=mean(oneshot_average_correct_rate2);average_correct_rate2_std=std(oneshot_average_correct_rate2);
disp(['correct rate for method 2:  ', num2str(average_correct_rate2),'  std=',num2str(average_correct_rate2_std)])
average_correct_rate3=mean(oneshot_average_correct_rate3);average_correct_rate3_std=std(oneshot_average_correct_rate3);
disp(['correct rate for method 3:  ', num2str(average_correct_rate3),'  std=',num2str(average_correct_rate3_std)])


