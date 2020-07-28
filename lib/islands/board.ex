# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Board do
  @moduledoc """
  Models a `board` in the _Game of Islands_.
  \n##### #{Islands.Config.get(:book_ref)}
  """

  alias __MODULE__
  alias __MODULE__.Response
  alias Islands.{Coord, Island}

  @island_types [:atoll, :dot, :l_shape, :s_shape, :square]

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:islands, :misses]
  defstruct [:islands, :misses]

  @type islands :: %{Island.type() => Island.t()}
  @type t :: %Board{islands: islands, misses: Island.coords()}

  @spec new :: t
  def new, do: %Board{islands: %{}, misses: MapSet.new()}

  @spec position_island(t, Island.t()) :: t | {:error, atom}
  def position_island(%Board{} = board, %Island{} = island) do
    if overlaps_board_islands?(island, board.islands),
      do: {:error, :overlapping_island},
      else: put_in(board.islands[island.type], island)
  end

  @spec all_islands_positioned?(t) :: boolean
  def all_islands_positioned?(%Board{} = board) do
    Enum.all?(@island_types, &Map.has_key?(board.islands, &1))
  end

  @spec guess(t, Coord.t()) :: Response.t()
  def guess(%Board{} = board, %Coord{} = guess) do
    board |> Response.check_guess(guess) |> Response.format_response(board)
  end

  @spec forested_types(t) :: [Island.type()]
  def forested_types(%Board{islands: islands} = _board) do
    islands
    |> Map.values()
    |> Enum.filter(&Island.forested?/1)
    |> Enum.map(& &1.type)
  end

  @spec hits(t) :: non_neg_integer
  def hits(%Board{islands: islands} = _board) do
    islands
    |> Map.values()
    |> Enum.map(&MapSet.size(&1.hits))
    |> Enum.sum()
  end

  @spec misses(t) :: non_neg_integer
  def misses(%Board{misses: misses} = _board), do: MapSet.size(misses)

  @spec grid_positions(t) :: %{Island.type() => map}
  def grid_positions(%Board{islands: islands} = _board) do
    for {type, island} <- islands, into: %{} do
      {type, Island.grid_position(island)}
    end
  end

  @spec hit_cells(t) :: %{Island.type() => [<<_::2, _::_*8>>]}
  def hit_cells(%Board{islands: islands} = _board) do
    for {type, island} <- islands, into: %{} do
      {type, Island.hit_cells(island)}
    end
  end

  @spec miss_squares(t) :: %{:squares => [Coord.square()]}
  def miss_squares(%Board{misses: misses} = _board) do
    %{squares: Enum.map(misses, &Coord.to_square/1)}
  end

  ## Private functions

  @spec overlaps_board_islands?(Island.t(), Board.islands()) :: boolean
  defp overlaps_board_islands?(new_island, islands) do
    Enum.any?(islands, fn {type, island} ->
      type != new_island.type and Island.overlaps?(new_island, island)
    end)
  end
end
