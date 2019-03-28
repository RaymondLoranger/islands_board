# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Board do
  use PersistConfig

  @book_ref Application.get_env(@app, :book_ref)

  @moduledoc """
  Models a `board` for the _Game of Islands_.
  \n##### #{@book_ref}
  """

  alias __MODULE__
  alias __MODULE__.Response
  alias Islands.{Coord, Island}

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:islands, :misses]
  defstruct [:islands, :misses]

  @type islands :: %{Island.type() => Island.t()}
  @type t :: %Board{islands: islands, misses: Island.coords()}

  @island_types Application.get_env(@app, :island_types)

  @spec new() :: t
  def new(), do: %Board{islands: %{}, misses: MapSet.new()}

  @spec position_island(t, Island.t()) :: t | {:error, atom}
  def position_island(%Board{} = board, %Island{} = island) do
    if overlaps_board_island?(board.islands, island),
      do: {:error, :overlapping_island},
      else: put_in(board.islands[island.type], island)
  end

  @spec all_islands_positioned?(t) :: boolean
  def all_islands_positioned?(%Board{} = board) do
    Enum.all?(@island_types, &Map.has_key?(board.islands, &1))
  end

  @spec guess(t, Coord.t()) :: Response.t()
  def guess(%Board{} = board, %Coord{} = guess) do
    guess |> Response.check_guess(board) |> Response.format_response(board)
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

  ## Private functions

  @spec overlaps_board_island?(Board.islands(), Island.t()) :: boolean
  defp overlaps_board_island?(islands, new_island) do
    Enum.any?(islands, fn {type, island} ->
      type != new_island.type and Island.overlaps?(island, new_island)
    end)
  end
end
