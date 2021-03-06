defmodule Islands.Board.Response do
  alias Islands.{Board, Coord, Island}

  @type guess_check :: {:hit, Island.t()} | {:miss, Coord.t()}
  @type t :: {:hit | :miss, Island.type() | :none, :no_win | :win, Board.t()}

  @spec check_guess(Board.t(), Coord.t()) :: guess_check
  def check_guess(%Board{} = board, %Coord{} = guess) do
    Enum.find_value(board.islands, {:miss, guess}, fn {_type, island} ->
      case Island.guess(island, guess) do
        {:hit, island} -> {:hit, island}
        :miss -> false
      end
    end)
  end

  @spec format_response(guess_check, Board.t()) :: t
  def format_response({:hit, island} = _guess_check, %Board{} = board) do
    board = put_in(board.islands[island.type], island)
    {:hit, forest_check(island), win_check(board), board}
  end

  def format_response({:miss, guess} = _guess_check, %Board{} = board) do
    board = update_in(board.misses, &MapSet.put(&1, guess))
    {:miss, :none, :no_win, board}
  end

  ## Private functions

  @spec forest_check(Island.t()) :: Island.type() | :none
  defp forest_check(island) do
    if Island.forested?(island), do: island.type, else: :none
  end

  @spec win_check(Board.t()) :: :win | :no_win
  defp win_check(board), do: if(all_forested?(board), do: :win, else: :no_win)

  @spec all_forested?(Board.t()) :: boolean
  defp all_forested?(%Board{islands: islands} = _board) do
    Enum.all?(islands, fn {_type, island} -> Island.forested?(island) end)
  end
end
