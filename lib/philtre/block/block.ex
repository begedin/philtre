defmodule Philtre.Block do
  @moduledoc """
  Defines what the structure of a block should be
  """

  @doc """
  Takes the struct for the specific block type and returns its id
  """
  @callback id(struct) :: String.t()

  @doc """
  Takes the struct for the specific block type and returns its string type
  """
  @callback type(struct) :: String.t()

  @doc """
  Takes the struct for the specific block type and returns its data serialized
  as a json-encodeable map with string keys.
  """
  @callback data(struct) :: %{required(String.t()) => any}

  @doc """
  Takes in the block id and the serialized data and returns the struct for the
  block.
  """
  @callback normalize(String.t(), any) :: struct
end
