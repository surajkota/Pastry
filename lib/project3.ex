defmodule Project3 do
  @moduledoc """
  Documentation for Project3.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Project3.hello
      :world

  """
  def main(args) do
    process(args)
  end

  def process([]) do
    IO.puts "No arguments given"
  end

  def process(args) do
    {numNodes, ""} = Integer.parse(Enum.at(args, 0))
    numRequest = Integer.parse(Enum.at(args, 1))
    logN = round(Float.ceil(Math.log(numNodes)/Math.log(4)))
    #IO.puts "log " <> inspect(logN)
    maxNodes = Math.pow(4, logN)
    #change here to numNodes if routing fails many times
    #ranList = Enum.shuffle(Enum.to_list(1..maxNodes))
    ranList = Enum.shuffle(Enum.to_list(1..numNodes))
    createNodes(Enum.take(ranList,numNodes), numNodes, logN)
    :global.register_name(:server, self())
    :global.sync()
    firstGuy = :global.whereis_name(Enum.at(ranList,0))
    toGuy = :global.whereis_name(Enum.random(ranList))
    GenServer.cast firstGuy, {:route, toGuy}
    loop(ranList, 1, numRequest, 0)
  end

  def loop(ranList, currentR, maxR, i) do
    receive do
      {sender, :firstmsg} ->
        IO.puts "THe ENd"
  end
  end

  def createNodes(ranList, numNodes, logN) do
    IO.puts "id list " <> inspect(ranList)
    if numNodes != 0 do
      thisId = Enum.at(ranList, numNodes-1)
      IO.puts "myId " <> inspect(thisId)
      listMinusMe = ranList--[thisId]
      rTable = Enum.reduce(listMinusMe, Matrix.new(logN, 4, -1), fn(eachId, rT) -> 
        chrThisId = toEqualLen(Integer.to_string(thisId, 4),logN)
        chrEachId = toEqualLen(Integer.to_string(eachId, 4), logN)
        dPrefix = calcPre(chrThisId, chrEachId, 0)
        #IO.puts inspect(thisId) <> " = " <>inspect(chrThisId) <> "my " <> inspect(eachId) <> " = " <>inspect(chrEachId) <> "other " <> inspect(dPrefix)
        #IO.puts "mat" <> inspect(rT)
        #IO.puts "elem " <> inspect(Matrix.elem(rT, dPrefix, Enum.at(chrEachId,dPrefix)))
        if Matrix.elem(rT, dPrefix, (Enum.at(chrEachId,dPrefix)-48)) == -1 do
          rT = Matrix.set(rT, dPrefix, (Enum.at(chrEachId, dPrefix)-48), eachId)
        end
        rT
      end)
      IO.inspect rTable
      lLeaf = Enum.reduce(listMinusMe, [], fn(node, acc) ->
        #IO.inspect node
        #IO.puts inspect(acc)
            if(node > thisId && !Enum.member?(acc, node)) do  #larger leaf
                if length(acc) < 4 do
                    acc = acc ++ [node]
                else
                    if node < Enum.max(acc) do 
                        acc = List.delete(acc, Enum.max(acc))
                        acc = acc ++ [node] 
                    else 
                        acc
                    end                    
                end  
            else 
                acc
            end 
        end) 
        
        sLeaf = Enum.reduce listMinusMe, [], fn(node, acc) ->
            #IO.puts inspect(node) <> " " <> inspect(acc)
                if(node < thisId && !Enum.member?(acc, node)) do  #larger leaf
                    if length(acc) < 4 do
                        acc = acc ++ [node]
                    else
                        if node > Enum.min(acc) do 
                            acc = List.delete(acc, Enum.min(acc))
                            acc = acc ++ [node] 
                        else 
                            acc
                        end                    
                    end  
                else 
                    acc
                end 
            end 
        IO.puts inspect(Enum.at(lLeaf,1)) <> " L DONE" <> inspect(lLeaf)<> " len: " <> inspect(length(lLeaf))
        IO.puts inspect(Enum.at(sLeaf,1)) <> " S DONE " <> inspect(sLeaf) <> " len: " <> inspect(length(sLeaf))
        
      {:ok, heroPid} = PastryHero.start_link(thisId, lLeaf, sLeaf, rTable, ranList, logN)
      :global.register_name(thisId, heroPid)
      createNodes(ranList, numNodes-1, logN)
    else
      ranList
    end
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

