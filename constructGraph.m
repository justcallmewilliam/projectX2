function [A, param]= constructGraph(data, nbclusters, method, param, varargin)

%%
%by lance, 23 May 2016
%Construct normalized graph according to specific method and param.
% 
%input:
% data: X feature matrix dim: R^{m*n} (m features & n samples)
% nbclusters: number of clusters
% method: str. string indicating method used to construct graphs
% param: parameters for the method.
%output:
% A_norm: normalized graph R^{n*n}
% param: the new param obtained from where the CLR fails
%%

data = DataNormalization(data);

LapMatrixChoices = {'unormalized', 'sym', 'rw'};
func = {'gaussdist','knn','eps_neighbor','CLR'};
V = numel(func); % number of graphs from data (may need to put this part into graph section later)

if numel(varargin) == 0
   LapMatrixChoice = LapMatrixChoices{2};   
elseif  numel(varargin) == 1
   LapMatrixChoice = varargin{1};
end

switch method
    case 'gaussdist'
        wmat = SimGraph_Full(data, param);
        
    case 'knn'
        Type = 1; %Type = 1 normal, Type = 2 mutual
        k = param(1); %number of neighborhood
        wmat = full(KnnGraph(data, k, Type, param(2)));
        %[n,d]=knnsearch(x,y,'k',10,'distance','minkowski','p',5);
        
    case 'eps_neighbor'
        wmat = full(SimGraph_Epsilon(data, param));
        
    case 'CLR'
        flag = 0;
        while flag == 0
            try
                [~, wmat] = CLR_main(data, nbclusters, param);
                flag = 1;
            catch
                warning('Problem: set new m value because nbclusters is less than number of connected components');
                param = param + 1;
            end
        end
        
    case 'SelfTune'
        wmat = SelfTune(data, param);
        
    case 'ULGE'  
        [wmat, ~] = ULGE(data', param{:});
        
end

dmat = diag(sum(wmat, 2));

switch LapMatrixChoice
    case 'unormalized'
        %A_norm{v} = dmat - wmat;
        A = wmat;
    case 'sym'
        %A_norm{v} = eye(nbsamples) - (dmat^-0.5) * wmat * (dmat^-0.5);
        A = (dmat^-0.5) * wmat * (dmat^-0.5);
    case 'rw'
        %A_norm{v} = eye(nbsamples) - (dmat^-1) * wmat;
        A = (dmat^-1) * wmat;
end
A = (A+A')/2; % make the constructed graph symmetric to avoid small 
              % computational turbulence which cause symmetric elements
                
if ~isreal(A)
    A = real(A);
end

