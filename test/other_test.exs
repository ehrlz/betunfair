defmodule OtherTests do

  defp is_error(:error),do: true
  defp is_error({:error,_}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok,_}), do: true
  defp is_ok(_), do: false

end
