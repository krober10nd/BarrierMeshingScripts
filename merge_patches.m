clearvars; close all; clc;
%% Merge patches into parent mesh


PARENT = 'GSB_V4_with_lowered9_updates.14'; 
mPARENT = msh(PARENT);

files = {'FI','SI','RI','NI','MI','JI'};
for i = 1 : 6
    load(files{i})
    mPATCH{i} = m4;
end

tmp = mPARENT; 
for i = 1 : 6
    tmp = plus(mPATCH{i},tmp,'arb',{'lock_dis',500/111e3});
end
