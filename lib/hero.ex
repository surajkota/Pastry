defmodule PastryHero do 
    use GenServer

    def start_link(myId, lLeaf, sLeaf, rTable, rList, logN) do
        GenServer.start_link(__MODULE__, [myId, lLeaf, sLeaf, rTable, rList, logN])
    end

    def handle_cast({:route, {toId, hops}}, [myId, lLeaf, sLeaf, rTable, rList, logN]) do 
        #IO.puts inspect(self()) <> " me:" <> inspect(myId) <> " to:" <> inspect(toId)
        #IO.puts "smallL: " <> inspect(sLeaf) <> " largeL: " <> inspect(lLeaf)
        #IO.puts "rTable: " <> inspect(rTable)

        if myId == toId do 
            #call route finish
            #IO.puts "Reached destination"
            send :global.whereis_name(:server), {self(), :firstmsg, hops}         
            #send :global.whereis_name(:server), {self(), :firstmsg, 0}         
        else 
            diff = Enum.max(rList) + 10
            nearest = {-1, diff}
            # check in smaller leaf
            if length(sLeaf) > 0 && toId < myId && toId >= Enum.min(sLeaf) do 
                nearest = Enum.reduce sLeaf, {-1, diff}, fn (node, acc) ->
                    #IO.inspect node
                    {_, b} = acc # b = diff
                    if abs(node - toId) < b do 
                        diff = abs(node - toId)                  
                        acc = {node , diff}                          
                    else 
                        acc
                    end 
                end 
                #IO.puts "nearest" 
                #IO.puts inspect(nearest)
            end

            #check in larger leaf 
            if length(lLeaf) > 0 && toId > myId && toId <= Enum.max(lLeaf) do 
                nearest = Enum.reduce lLeaf, {-1, diff}, fn (node, acc) ->
                    #IO.inspect node
                    {_, b} = acc # b is diff
                    if abs(node - toId) < b do 
                        diff = abs(node - toId)                  
                        acc = {node , diff}                          
                    else 
                        acc
                    end 
                end 
                #IO.puts "nearest" 
                #IO.puts inspect(nearest)
            end 
            {routeTo, _} = nearest
            #IO.inspect "if in leaf " <> inspect(routeTo)
            if routeTo != -1 do
                GenServer.cast :global.whereis_name(routeTo), {:route, {toId, hops+1}}
                #GenServer.cast :global.whereis_name(routeTo), {:route, toId}
            else
                #search in routing table
                chrMyId = toEqualLen(Integer.to_string(myId, 4),logN)
                chrToId = toEqualLen(Integer.to_string(toId, 4), logN)
                dPrefix = calcPre(chrMyId, chrToId, 0)
                if Matrix.elem(rTable, dPrefix, (Enum.at(chrToId, dPrefix)-48)) != -1 do
                    GenServer.cast :global.whereis_name(Matrix.elem(rTable, dPrefix, (Enum.at(chrToId,dPrefix)-48))), {:route, {toId, hops+1}}
                    #GenServer.cast :global.whereis_name(Matrix.elem(rTable, dPrefix, (Enum.at(chrToId,dPrefix)-48))), {:route, toId}
                else
                    #if not found in routing table, forward to some node in leaf set according to-
                    cond do
                        toId > myId && length(lLeaf) > 0 ->
                            GenServer.cast :global.whereis_name(Enum.max(lLeaf)), {:route, {toId, hops + 1}}
                            #GenServer.cast :global.whereis_name(Enum.max(lLeaf)), {:route, toId}
                        toId < myId && length(sLeaf) > 0 -> 
                            GenServer.cast :global.whereis_name(Enum.min(sLeaf)), {:route, {toId, hops + 1}}
                            #GenServer.cast :global.whereis_name(Enum.min(sLeaf)), {:route, toId}
                        true ->
                            #IO.puts "Dead end"
                            GenServer.cast :global.whereis_name(Enum.random(rList)), {:route, {toId, 0}}
                    end
                end
            end
            
        end
        {:noreply, [myId, lLeaf, sLeaf, rTable, rList, logN]}        
    end 

    def handle_call({:nothing, {toId, hops}}, [myId, lLeaf, sLeaf, rTable, rList, logN]) do 
        {:reply, :ok, [myId, lLeaf, sLeaf, rTable, rList, logN]}
    end

    def calcPre(a, b, diff) do
        if diff < length(a) and Enum.at(a, diff) == Enum.at(b, diff) do
          calcPre(a, b, diff + 1)
        else
          diff
        end
      end
    
      def toEqualLen(a, logN) do
        diff = logN - String.length(a)
        if diff > 0 do
          a = "0" <> a
          toEqualLen(a, logN)
        else
          #IO.puts "str " <> a
          String.to_charlist(a)
        end
      end

end 
