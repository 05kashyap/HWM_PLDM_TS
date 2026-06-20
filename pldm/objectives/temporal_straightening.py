from dataclasses import dataclass
from typing import NamedTuple, List

import torch
from torch import nn
import torch.nn.functional as F

from pldm.configs import ConfigBase
from pldm.models.jepa import ForwardResult

class TSLossInfo(NamedTuple):
    total_loss: torch.Tensor
    curv_loss: torch.Tensor
    loss_name: str = "ts"
    name_prefix: str = ""

    def build_log_dict(self):
        return {
            f"{self.name_prefix}/{self.loss_name}_total_loss": self.total_loss.item(),
            f"{self.name_prefix}/{self.loss_name}_curv_loss": self.curv_loss.item(),
        }

@dataclass
class TemporalStraighteningConfig(ConfigBase):
    curv_coeff: float = 1.0  # The lambda weight for the penalty

class TemporalStraighteningObjective(nn.Module):
    def __init__(self, config: TemporalStraighteningConfig, repr_dim: int, pred_attr: str = "obs", name_prefix: str = ""):
        super().__init__()
        self.config = config
        self.name_prefix = name_prefix
        self.pred_attr = pred_attr

    def __call__(self, _batch, result: List[ForwardResult]) -> TSLossInfo:
        # L1 training only requires the final hierarchical result
        res = result[-1] 
        
        # Extract the flattened embeddings from the Impala encoder
        if self.pred_attr == "state":
            encodings = res.backbone_output.encodings
        elif self.pred_attr == "obs":
            encodings = res.backbone_output.obs_component
        else:
            raise NotImplementedError

        # Encodings shape is typically (Time, Batch, Features)
        if encodings.shape[0] < 3:
            # We need at least 3 timesteps to calculate two consecutive velocities
            loss = torch.zeros(1, device=encodings.device, requires_grad=True)
        else:
            # Calculate velocities v_t
            velocities = encodings[1:] - encodings[:-1] 
            
            v_t = velocities[:-1]     # Velocity at step t
            v_t_next = velocities[1:] # Velocity at step t+1
            
            # Calculate cosine similarity across the feature dimension
            cos_sim = F.cosine_similarity(v_t, v_t_next, dim=-1)
            
            # The loss minimizes curvature (forces cos_sim towards 1)
            loss = (1.0 - cos_sim).mean()

        total_loss = self.config.curv_coeff * loss

        return TSLossInfo(
            total_loss=total_loss,
            curv_loss=loss,
            loss_name=f"ts_{self.pred_attr}",
            name_prefix=self.name_prefix
        )