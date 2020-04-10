%% Generate connectivity matrices
function connect_matrix=cmatrix(dim)
connect_matrix=zeros(dim);
for i=1:dim
    for j=1:dim
        if i==j
            connect_matrix(i,j)=1;
        else
            connect_matrix(i,j)=randi([0 1], 1 ,1);
        end
    end
end