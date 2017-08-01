module sracos

importall racos_common, objective, parameter, zoo_global, solution,
  racos_classification, tool_function

using Base.Dates.now

export SRacos, sracos_opt!

type SRacos
  rc::RacosCommon
  function SRacos()
    return new(RacosCommon())
  end
end

function sracos_opt!(sracos::SRacos, objective::Objective, parameter::Parameter;
  strategy="WR", ub=1)
  rc = sracos.rc
  clear!(rc)
  rc.objective = objective
  rc.parameter = parameter
  init_attribute!(rc)
  i = 0
  iteration_num = rc.parameter.budget - rc.parameter.train_size
  time_log1 = now()
  while i < iteration_num
    i += 1
    if rand(rng, Float64) < rc.parameter.probability
      classifier = RacosClassification(rc.objective.dim, rc.positive_data,
        rc.negative_data, ub=ub)
      # println(classifier)
      # zoolog("before classification")
      mixed_classification(classifier)
      # zoolog("after classification")
      solution, distinct_flag = distinct_sample_classifier(rc, classifier, data_num=rc.parameter.train_size)
    else
      solution, distinct_flag = distinct_sample(rc, rc.objective.dim)
    end
    #painc stop
    if isnull(solution)
      return rc.best_solution
    end
    if !distinct_flag
      continue
    end
    obj_eval(objective, solution)
    # sol_print(solution)
    bad_ele = replace(rc.positive_data, solution, "pos")
    replace(rc.negative_data, bad_ele, "neg", strategy=strategy)
    rc.best_solution = rc.positive_data[1]
    if i == 4
      time_log2 = now()
      # second
      expected_time = (parameter.budget - parameter.train_size) *
        (Dates.value(time_log2 - time_log1) / 1000) / 5
      if !isnull(rc.parameter.time_budget)
        expected_time = min(expected_time, rc.parameter.time_budget)
      end
      if expected_time > 5
        zoolog(string("expected remaining running time: ", convert_time(expected_time)))
      end
    end
    # time budget check
    if !isnull(rc.parameter.time_budget)
      if expected_time >= rc.parameter.time_budget
        zoolog("time_budget runs out")
        return rc.best_solution
      end
    end
    # terminal_value check
    if !isnull(rc.parameter.terminal_value)
      if rc.best_solution.value <= rc.parameter.terminal_value
        zoolog("terminal_value function value reached")
        return rc.best_solution
      end
    end
  end
  return rc.best_solution
end

function replace(iset, x, iset_type; strategy="WR")
  if strategy == "WR"
    return strategy_wr(iset, x, iset_type)
  elseif strategy == "RR"
    return strategy_rr(iset, x)
  elseif strategy == "LM"
    best_sol, best_index = find_min(iset)
    return strategy_lm(iset, best_sol, x)
  else
    zoolog("No such strategy")
  end
end

# Find first element larger than x
function binary_search(iset, x, ibegin::Int64, iend::Int64)
  x_value = x.value
  if x_value <= iset[ibegin].value
    return ibegin
  end
  if x_value >= iset[end].value
    return iend + 1
  end
  if iend == ibegin + 1
    return iend
  end
  mid = div(ibegn + iend, 2)
  if x_value <= iset[mid].value
    return binary_search(iset, x, ibegin, mid)
  else
    return binary_search(iset, x, mid, iend)
  end
end

# Worst replace
function strategy_wr(iset, x, iset_type)
  if iset_type == "pos"
    index = binary_search(iset, x, 1, length(iset))
    insert!(iset, index, x)
    worst_ele = pop!(iset)
  else
    worst_ele, worst_index = find_max(iset)
    if worst_ele.value > x.value
      iset[worst_index] = x
    else
      worst_ele = x
    end
  end
  return worst_ele
end

# Random replace
function strategy_rr(iset, x)
  len_iset = length(iset)
  replace_index = rand(rng, 1:len_iset)
  replace_ele = iset[replace_index]
  iset[replace_index] = x
  return replace_ele
end

function strategy_lm(iset, best_sol, sol)
  farthest_dis = 0
  farthest_index = 0
  for i in 1:length(iset)
    dis = mydistance(iset[i].x, best_sol.x)
    if dis > farthest_dis
      farthest_dis = dis
      farthest_index = i
    end
  end
  farthest_ele = iset[farthest_index]
  iset[farthest_index] = sol
  return farthest_ele
end

end
