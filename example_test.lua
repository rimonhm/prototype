

require 'torch'
require 'optim'
require 'nn'

-- loss to a text file
logger = optim.Logger('loss_log.txt')

----------------------------------------------------------------------
-- 1. Create the training data

data = torch.Tensor{
   {40,  6,  4},
   {44, 10,  4},
   {46, 12,  5},
   {48, 14,  7},
   {52, 16,  9},
   {58, 18, 12},
   {60, 22, 14},
   {68, 24, 20},
   {74, 26, 21},
   {80, 32, 24}
}


----------------------------------------------------------------------
-- 2. Define the model (predictor)



model = nn.Sequential()                 -- define the container
ninputs = 2; noutputs = 1
model:add(nn.Linear(ninputs, noutputs)) -- define the only module


----------------------------------------------------------------------
-- 3. Define a loss function, to be minimized.



criterion = nn.MSECriterion()


----------------------------------------------------------------------
-- 4. Train the model



x, dl_dx = model:getParameters()



feval = function(x_new)
   -- set x to x_new, if differnt
   -- (in this simple example, x_new will typically always point to x,
   -- so the copy is really useless)
   if x ~= x_new then
      x:copy(x_new)
   end

   -- select a new training sample
   _nidx_ = (_nidx_ or 0) + 1
   if _nidx_ > (#data)[1] then _nidx_ = 1 end

   local sample = data[_nidx_]
   local target = sample[{ {1} }]      -- this syntax allows
   local inputs = sample[{ {2,3} }]    -- slicing of arrays.

   -- reset gradients (gradients are always accumulated, to accommodate 
   -- batch methods)
   dl_dx:zero()

   -- evaluate the loss function and its derivative wrt x, for that sample
   local loss_x = criterion:forward(model:forward(inputs), target)
   model:backward(inputs, criterion:backward(model.output, target))

   -- return loss(x) and dloss/dx
   return loss_x, dl_dx
end


--   + a learning rate: the size of the step taken at each stochastic 
--     estimate of the gradient
--   + a weight decay, to regularize the solution (L2 regularization)
--   + a momentum term, to average steps over time
--   + a learning rate decay, to let the algorithm converge more precisely

sgd_params = {
   learningRate = 1e-3,
   learningRateDecay = 1e-4,
   weightDecay = 0,
   momentum = 0
}

--using cross-validation.

-- we cycle 1e4 times over our training data
for i = 1,1e4 do

   -- this variable is used to estimate the average loss
   current_loss = 0

   -- an epoch is a full loop over our training data
   for i = 1,(#data)[1] do

      -- optim contains several optimization algorithms. 
     
      
      _,fs = optim.sgd(feval,x,sgd_params)

      -- Functions in optim all return two things:
      

      current_loss = current_loss + fs[1]
   end

   -- report average error on epoch
   current_loss = current_loss / (#data)[1]
   print('current loss = ' .. current_loss)
   
   logger:add{['training error'] = current_loss}
   logger:style{['training error'] = '-'}
   logger:plot()  
end

----------------------------------------------------------------------
-- 5. Test the trained model.



text = {40.32, 42.92, 45.33, 48.85, 52.37, 57, 61.82, 69.78, 72.19, 79.42}

print('id  approx   text')
for i = 1,(#data)[1] do
   local myPrediction = model:forward(data[i][{{2,3}}])
   print(string.format("%2d  %6.2f %6.2f", i, myPrediction[1], text[i]))
end