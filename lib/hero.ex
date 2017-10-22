defmodule PastryHero do 
    use GenServer

    def start_link(myId, lLeaf, sLeaf, rTable, rList, logN) do
        GenServer.start_link(__MODULE__, [myId, lLeaf, sLeaf, rTable, rList, logN])
    end

    def handle_cast({:route, toId}, [myId, lLeaf, sLeaf, rTable, rList, logN]) do 
        IO.inspect self()
        IO.inspect toId
        IO.inspect myId
        IO.inspect sLeaf 
        IO.inspect lLeaf
        
        if myId == toId do 
            #call route finish
            IO.puts "Reached destination"
            send :global.whereis_name(:server), {self(),:firstmsg}         
        else 
            diff = Enum.max(rList) + 10
            nearest = {-1, diff}
            # check in smaller leaf
            if length(sLeaf) > 0 && toId < myId && toId >= Enum.min(sLeaf) do 
                nearest = Enum.reduce sLeaf, {-1, diff}, fn (node, acc) ->
                    #IO.inspect node
                    {a, b} = acc
                    if abs(node - toId) < b do 
                        diff = abs(node - toId)                  
                        acc = {node , diff}                          
                    else 
                        acc
                    end 
                end 
                IO.puts "nearest" 
                IO.puts inspect(nearest)
            end

            #check in larger leaf 
            if length(lLeaf) > 0 && toId > myId && toId <= Enum.max(lLeaf) do 
                nearest = Enum.reduce lLeaf, {-1, diff}, fn (node, acc) ->
                    #IO.inspect node
                    {a, b} = acc
                    if abs(node - toId) < b do 
                        diff = abs(node - toId)                  
                        acc = {node , diff}                          
                    else 
                        acc
                    end 
                end 
                IO.puts "nearest" 
                IO.puts inspect(nearest)
            end 
            {routeTo,_} = nearest
            IO.inspect "if in leaf" <> routeTo
            if routeTo != -1 do
                GenServer.cast :global.whereis_name(routeTo), {:route, toId}    
            else
                #search in routing table
                
                if 
            end
            
        end
        {:noreply, [myId, lLeaf, sLeaf, rTable, rList, logN]}        
    end 

    def handle_call({:nothing, toId}, [myId, lLeaf, sLeaf, rTable, rList, logN]) do 
        {:reply, :ok, [myId, lLeaf, sLeaf, rTable, rList, logN]}
    end
end 
